import urllib.request
import json
import re

url = 'https://api.curseforge.com/v1/mods/search?gameId=432&classId=6&searchFilter=IronsArms'
req = urllib.request.Request(url, headers={'x-api-key': '/f5m1T7vG/C3w3e4U7t7P/H0q4.T6Yy5vV2/W3K/2Y/W5W'})

try:
    with urllib.request.urlopen(req) as response:
        data = json.loads(response.read().decode())
        if 'data' in data and len(data['data']) > 0:
            mod_id = data['data'][0]['id']
            print(f"Mod ID: {mod_id}")
            
            files_url = f"https://api.curseforge.com/v1/mods/{mod_id}/files"
            req2 = urllib.request.Request(files_url, headers={'x-api-key': '/f5m1T7vG/C3w3e4U7t7P/H0q4.T6Yy5vV2/W3K/2Y/W5W'})
            with urllib.request.urlopen(req2) as resp2:
                files_data = json.loads(resp2.read().decode())
                for file in files_data['data']:
                    print(f"File: {file['fileName']}, URL: {file['downloadUrl']}")
except Exception as e:
    print(f"Error: {e}")
