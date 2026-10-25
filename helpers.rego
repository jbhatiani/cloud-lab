package azure.helpers

import rego.v1

get_param_default(params, name, default_val) := val if {
    val := object.get(params, name, {"defaultValue": default_val}).defaultValue
} else := default_val