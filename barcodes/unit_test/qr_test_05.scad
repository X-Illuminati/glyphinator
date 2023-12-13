/* Unit Test 05: Version 5, Mask 7, ECC Low */
/* From https://en.wikipedia.org/wiki/File:Japan-qr-code-billboard.jpg */
use <../quick_response.scad>
use <../../util/stringlib.scad>
quick_response(
	qr_bytes(
		concat(
			ascii_to_vec("http://sagasou.mobi \r\n\r\nMEBKM:TITLE:"),
			[ //shift-jis encoded string "探そうモビで専門学校探し！"
				146,84,
				130,187,
				130,164,
				131,130,
				131,114,
				130,197,
				144,234,
				150,229,
				138,119,
				141,90,
				146,84,
				130,181,
				129,73
			],
			ascii_to_vec(";URL:http\\://sagasou.mobi;;")
		)
	),
	mask=7, ecc_level=0,
	mark="black");

