#!/usr/bin/ucode
push(REQUIRE_SEARCH_PATH,
        "/usr/lib/ucode/*.so",
        "/usr/share/ucentral/*.uc");

let fs = require("fs");

if (!key) { fprintf(stderr, "Missing API key\n"); exit(2); }
printf("CLI TEXT IS %s\n\n", cli_text);
let load_payload_obj = { op: "load", file: "/opt/vyatta/etc/config/config.boot" };
let load_payload_str = sprintf("%J", load_payload_obj);
let payload_obj = { op: op, string: cli_text };
let payload_str = sprintf("%J", payload_obj);
function sqq(s) {
    if (s == null)
        return "''";
    let parts = split(s, "'");
    return "'" + join("'\"'\"'", parts) + "'";
}
let url = host + "/config-file";
printf("url is %s\n",url);
let load_cmd = sprintf(
  "curl -skL --connect-timeout 3 -m 5 -X POST %s --form-string data=%s --form key=%s",
  sqq(url), sqq(load_payload_str), sqq(key)
);

printf("load_cmd is %s\n\n", load_cmd);
system(load_cmd);

let cmd = sprintf(
  "curl -skL --connect-timeout 3 -m 5 -X POST %s --form-string data=%s --form key=%s",
  sqq(url), sqq(payload_str), sqq(key)
);

printf("cmd is %s\n\n", cmd);
let rc = system(cmd);
return rc;
