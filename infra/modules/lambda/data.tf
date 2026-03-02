data "archive_file" "archive" {
  for_each    = { for function in var.function_config : function.name => function }
  type        = "zip"
  source_file = "${path.module}/scripts/${each.value.filename}"
  output_path = "${path.module}/scripts/${each.value.name}.zip"
}
