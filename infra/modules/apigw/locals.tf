locals {
  path_method_list    = {
      for item in flatten([
        for ec in var.endpoint_configs : [
          for m in ec.methods : {
            path_part = ec.path_part
            method    = m
          }
        ]
      ]) : "${item.path_part}/${item.method}" => item
    }
}
