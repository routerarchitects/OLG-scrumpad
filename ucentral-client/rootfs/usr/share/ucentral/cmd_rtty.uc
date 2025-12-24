if (!args.id || !args.server || !args.port || !args.token || !args.timeout) {
	result_json({
		"error": 2,
		"text": "Invalid parameters.",
		"resultCode": -1
	});

	return;
}

if (restrict.rtty) {
	result_json({
		"error": 2,
		"text": "RTTY is restricted.",
		"resultCode": -1
	});

	return;
}


let cmd = sprintf("/usr/sbin/rtty -h %s -I %s -a -p %d -d '%s' -s -c /etc/ucentral/cert.pem -k /etc/ucentral/key.pem -t %s -e %d", 
    args.server, 
    args.id, 
    args.port, 
    args.description || "intel", 
    args.token, 
    args.timeout
);


system(cmd + "&");

result_json({
	"error": 0,
	"text": "Command was executed"
});
