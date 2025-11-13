#!/usr/bin/ucode
push(REQUIRE_SEARCH_PATH,
        "/usr/lib/ucode/*.so",
        "/usr/share/ucentral/*.uc");

let fs = require("fs");

if (!key) { fprintf(stderr, "Missing API key\n"); exit(2); }
printf("CLI TEXT IS %s\n\n", cli_text);
/* TODO: pass as container environment variable for load */
let loadapi_payload_obj = { op: "load", file: "/opt/vyatta/etc/config/config.boot" };
let loadapi_payload_str = sprintf("%J", loadapi_payload_obj);
let api_payload_obj = { op: op, string: cli_text };
let api_payload_str = sprintf("%J", api_payload_obj);
function quoteForShell(s) {
    if (s == null)
        return "''";
    let parts = split(s, "'");
    return "'" + join("'\"'\"'", parts) + "'";
}
let url = host + "/config-file";
printf("url is %s\n",url);
let api_load_op_cmd = sprintf(
  "curl -skL --connect-timeout 3 -m 5 -X POST %s --form-string data=%s --form key=%s",
  quoteForShell(url), quoteForShell(loadapi_payload_str), quoteForShell(key)
);

printf("api_load_op_cmd is %s\n\n", api_load_op_cmd);
system(api_load_op_cmd);

let api_op_cmd = sprintf(
  "curl -skL --connect-timeout 3 -m 5 -X POST %s --form-string data=%s --form key=%s",
  quoteForShell(url), quoteForShell(api_payload_str), quoteForShell(key)
);

printf("api_op_cmd is %s\n\n", api_op_cmd);
let rc = system(api_op_cmd);
return rc;
