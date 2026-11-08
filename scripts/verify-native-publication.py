"""Block wrapper releases whose declared native dependencies are not public."""
from pathlib import Path
import hashlib, json, re, subprocess
root = Path(__file__).resolve().parent.parent
read = lambda name: (root / name).read_text()
version = re.search(r"^version: (.+)$", read('pubspec.yaml'), re.M)[1]
podspec = read('ios/push_platform_flutter.podspec')
assert re.search(r"s\.version\s*=\s*'([^']+)'", podspec)[1] == version, 'Flutter/pod versions differ'
assert re.search(r'^version = "([^"]+)"', read('android/build.gradle.kts'), re.M)[1] == version, 'Flutter/Gradle versions differ'
ios = re.search(r"s\.dependency 'PushPlatformSDK', '([^']+)'", podspec)[1]
android = re.search(r'com.pushplatform:sdk-android:([^"\s]+)', read('android/build.gradle.kts'))[1]
def get(url):
    return subprocess.check_output(['curl', '--fail', '--location', '--silent', '--show-error', '--retry', '3', '--max-time', '60', url])
for name in ['PushPlatformExtension', 'PushPlatformSDK']:
    shard = hashlib.md5(name.encode()).hexdigest()[:3]
    index = get('https://cdn.cocoapods.org/all_pods_versions_' + '_'.join(shard) + '.txt').decode()
    entry = next((line for line in index.splitlines() if line.startswith(name + '/')), '')
    assert ios in entry.split('/')[1:], f'{name} {ios} absent from public index'
    spec = json.loads(get(f'https://cdn.cocoapods.org/Specs/{"/".join(shard)}/{name}/{ios}/{name}.podspec.json'))
    assert spec['name'] == name and spec['version'] == ios, 'Unexpected pod name/version'
    assert spec['source'] == {'git': 'https://github.com/pushplatform/pushpilot-sdk-ios.git', 'tag': 'v' + ios}, 'Unexpected pod source'
    if name == 'PushPlatformSDK':
        assert spec['dependencies']['PushPlatformExtension'] == [ios], 'SDK/Extension versions differ'
base = f'https://raw.githubusercontent.com/pushplatform/pushpilot-sdk-android/maven/com/pushplatform/sdk-android/{android}/sdk-android-{android}'
module = json.loads(get(base + '.module'))
assert module['component']['group'] == 'com.pushplatform' and module['component']['module'] == 'sdk-android' and module['component']['version'] == android, 'Wrong Maven coordinate'
aar = get(base + '.aar')
assert hashlib.sha256(aar).hexdigest() == get(base + '.aar.sha256').decode().strip(), 'AAR checksum differs'
files = [f for variant in module['variants'] for f in variant.get('files', []) if f['name'].endswith('.aar')]
assert files and all(f['size'] == len(aar) and f['sha256'] == hashlib.sha256(aar).hexdigest() for f in files), 'AAR/module differs'
print(f'Flutter {version}: public CocoaPods {ios} + Maven {android} verified')
