import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  vus: 5,
  duration: "30s",
  thresholds: {
    http_req_duration: ["p(95)<2000", "p(99)<3000"],
    http_req_failed: ["rate<0.10"],
    http_reqs: ["rate>3"],
  },
};

export default function () {
  const BASE_URL = __ENV.BASE_URL;
  const TOKEN = __ENV.API_TOKEN;
  // Requested region to assert against response payload. Provide via workflow/env:
  // e.g. REQUEST_REGION=us-east-1 or fall back to REGION
  const REQUEST_REGION = __ENV.REQUEST_REGION || __ENV.REGION || "";

  const endpoints = [
    {
      path: "/greet",
      method: "GET",
    },
    {
      path: "/dispatch",
      method: "POST",
    },
  ];

  const params = {
    headers: {
      Authorization: `Bearer ${TOKEN}`,
      "Content-Type": "application/json",
    },
  };

  for (const endpoint of endpoints) {
    let response;
    const url = `${BASE_URL}${endpoint.path}`;

    if (endpoint.method === "GET") {
      response = http.get(url, params);
    } else {
      response = http.post(url, params);
    }

    const latencyMs =
      response.timings && response.timings.duration
        ? response.timings.duration
        : -1;

    // Parse JSON response body for the region field
    let bodyText = response.body || "";
    let parsed = null;
    try {
      if (typeof response.json === "function") {
        parsed = response.json();
      } else {
        parsed = JSON.parse(bodyText);
      }
    } catch (e) {
      parsed = null;
    }

    // Console output: status, latency, and response body for inspection
    console.log(
      `Request: ${endpoint.method} ${endpoint.path} -> status=${response.status} latency=${latencyMs}ms`,
    );
    // Output a short slice of body to avoid overly verbose logs
    if (bodyText && bodyText.length > 2000) {
      console.log(
        "Response body (truncated):",
        bodyText.substring(0, 2000) + "...",
      );
    } else {
      console.log("Response body:", bodyText);
    }

    // Checks: status, latency, and region equality when payload available
    const checks = {
      [`${endpoint.path} returns 200`]: (r) => r.status === 200,
      [`${endpoint.path} response time < 5000ms`]: (r) =>
        r.timings && r.timings.duration ? r.timings.duration < 5000 : false,
    };

    // Only assert region when we have a requested region and a parsed response
    if (REQUEST_REGION) {
      checks[`${endpoint.path} payload region matches requested region`] = (
        r,
      ) =>
        parsed &&
        parsed.region &&
        String(parsed.region) === String(REQUEST_REGION);
    }

    // Run checks
    const result = check(response, checks);
    // If region mismatch or request failed, log more details for debugging
    if (!result) {
      if (parsed && REQUEST_REGION && parsed.region !== REQUEST_REGION) {
        console.error(
          `Region mismatch: requested='${REQUEST_REGION}' response.region='${parsed.region}'`,
        );
      }
      // Log status code and first 500 chars of body for debugging
      console.error(
        `Failed checks for ${endpoint.path}: status=${response.status} latency=${latencyMs}ms`,
      );
    }
  }

  sleep(1);
}
