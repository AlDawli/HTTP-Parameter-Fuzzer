# HTTP-Parameter-Fuzzer
A simple but powerful bash-based parameter discovery tool for web application security testing.

✅ Common Parameter Testing - Built-in wordlist of 50+ common parameters
✅ JS File Analysis - Extract parameters from JavaScript files automatically
✅ Status Code Detection - Differentiate between 200/3xx/4xx/5xx responses
✅ Reflection Detection - Highlight parameter reflections for XSS testing
✅ Concurrent Testing - Multi-threaded fuzzing for faster results
✅ Multiple HTTP Methods - Support for GET and POST requests
✅ Output Logging - Save results to file for later analysis

# Requirements
bash (v4.0+)
curl
xargs (optional, for parallel processing)

# Usage
# Basic Examples
Test with built-in common parameters:
bash./param_fuzzer.sh -u "https://example.com/api/user"

# Use custom wordlist:
bash./param_fuzzer.sh -u "https://example.com/api" -w params.txt

Enable reflection detection (XSS testing):
bash./param_fuzzer.sh -u "https://example.com/search" -r

Extract parameters from JavaScript file:
bash./param_fuzzer.sh -u "https://example.com/api" -j "https://example.com/app.js"

POST method testing:
bash./param_fuzzer.sh -u "https://example.com/api/login" -m POST -w auth_params.txt

Verbose mode with output file:
bash./param_fuzzer.sh -u "https://example.com/api" -v -o results.txt

# Advanced Usage
Combine JS extraction with custom wordlist:
bash./param_fuzzer.sh -u "https://api.example.com/v1/users" \
  -j "https://example.com/static/main.js" \
  -w custom_params.txt \
  -r \
  -o results.txt

# Slow down requests to avoid rate limiting:
bash./param_fuzzer.sh -u "https://example.com/api" -d 1 -t 5

# Command Line Options
OptionDescriptionDefault-u, --urlTarget URL (required)--w, --wordlistCustom wordlist fileBuilt-in common params-m, --methodHTTP method (GET/POST)GET-j, --js-extractExtract parameters from JS file--r, --reflectHighlight parameter reflectionsfalse-t, --threadsNumber of concurrent threads10-d, --delayDelay between requests (seconds)0-o, --outputOutput results to file--v, --verboseVerbose outputfalse-h, --helpShow help message-
Output Interpretation

# The tool uses color-coded output to categorize responses:
🟢 Green [200] - Parameter accepted, successful response
🔴 Red [5xx] - Server error (might indicate injection point)
🟡 Yellow [4xx] - Client error (verbose mode only)
🔵 Cyan [3xx] - Redirect (verbose mode only)
🟣 Purple [REFLECTED] - Parameter value reflected in response (potential XSS)

# Wordlist Format
Create custom wordlists with one parameter per line:
id
user
token
api_key
callback
redirect_url
debug
admin
Example Output
╔═══════════════════════════════════════╗
║   HTTP Parameter Fuzzer v1.0.0        ║
║   Simple Parameter Discovery Tool     ║
╚═══════════════════════════════════════╝

[*] Starting parameter fuzzing...
[*] Target: https://example.com/api/user
[*] Method: GET
[*] Total parameters: 52
[*] Threads: 10

[200] id
[200] user [REFLECTED]
[200] debug
[500] admin
[200] token

[✓] Fuzzing complete!
[✓] Results saved to: results.txt
Security Considerations

Always obtain proper authorization before testing any web application
Use rate limiting (-d flag) to avoid overwhelming target servers
This tool is for educational and authorized security testing only
Be aware of your local laws regarding security testing

# Use Cases
Bug Bounty Hunting - Discover hidden parameters in web applications
Penetration Testing - Find undocumented API parameters
XSS Research - Identify reflection points for XSS testing
API Security Testing - Test for parameter pollution and injection
Web App Reconnaissance - Map out application functionality

# Creating Custom Wordlists
You can create domain-specific wordlists by analyzing:

JavaScript files
API documentation
HTML forms
Previous parameter discoveries
Common patterns in similar applications

# Troubleshooting
Issue: No output or "command not found"
Ensure the script is executable: chmod +x param_fuzzer.sh
Check if curl is installed: which curl

Issue: Slow performance
Increase threads: -t 20
Remove delay: -d 0
Use smaller wordlist
Issue: Rate limiting or blocking
Decrease threads: -t 5
Add delay: -d 2
Use proxy or VPN

# Contributing
Contributions are welcome! Please feel free to submit a Pull Request.

# Fork the repository
Create your feature branch (git checkout -b feature/AmazingFeature)
Commit your changes (git commit -m 'Add some AmazingFeature')
Push to the branch (git push origin feature/AmazingFeature)
Open a Pull Request

# Roadmap
 Add support for custom headers
 Cookie handling
 Proxy support
 JSON/XML parameter testing
 Response diff comparison
 Integration with other tools

# License
This project is licensed under the MIT License - see the LICENSE file for details.
Disclaimer
This tool is provided for educational purposes and authorized security testing only. The authors are not responsible for any misuse or damage caused by this program. Always ensure you have permission to test any systems you target.
