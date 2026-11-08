"""Build an isolated Flutter consumer with ordinary public native dependencies."""
from pathlib import Path
import argparse, json, re, subprocess, tempfile
parser = argparse.ArgumentParser()
parser.add_argument('--platform', choices=['ios', 'android'], required=True)
parser.add_argument('--published', action='store_true', help='Install this version from pub.dev instead of local plugin source')
args = parser.parse_args()
root = Path(__file__).resolve().parent.parent
version = re.search(r'^version: (.+)$', (root / 'pubspec.yaml').read_text(), re.M)[1]
consumer = Path(tempfile.mkdtemp(prefix='pushpilot-flutter-consumer-'))
print(f'Isolated consumer retained at {consumer}', flush=True)
def run(*command):
    return subprocess.run(command, cwd=consumer, check=True)
run('flutter', 'create', '--platforms=' + args.platform, '--project-name=pushpilot_consumer', '--org=com.pushplatform.verify', '--no-pub', str(consumer))
if args.published:
    run('flutter', 'pub', 'add', 'push_platform_flutter:' + version)
else:
    run('flutter', 'pub', 'add', 'push_platform_flutter', '--path', str(root))
# Reference the public Dart API so the native plugin is included in the app.
main = consumer / 'lib/main.dart'
main.write_text("import 'package:push_platform_flutter/push_platform_flutter.dart';\n" + main.read_text())
if args.platform == 'ios':
    subprocess.run(['pod', 'install', '--repo-update'], cwd=consumer / 'ios', check=True)
    run('flutter', 'build', 'ios', '--simulator', '--debug', '--no-codesign')
    lock = json.loads(subprocess.check_output(['ruby', '-ryaml', '-rjson', '-e', 'puts JSON.generate(YAML.load_file(ARGV[0]))', str(consumer / 'ios/Podfile.lock')], text=True))
    native = re.search(r"s\.dependency 'PushPlatformSDK', '([^']+)'", (root / 'ios/push_platform_flutter.podspec').read_text())[1]
    pods = [p if isinstance(p, str) else next(iter(p)) for p in lock['PODS']]
    for name in ['PushPlatformSDK', 'PushPlatformExtension']:
        assert f'{name} ({native})' in pods, 'Wrong public pod version'
        assert name not in lock.get('EXTERNAL SOURCES', {}), 'Native SDK source override hides a registry failure'
        assert any(name in names for repo, names in lock['SPEC REPOS'].items() if repo in ['trunk', 'https://cdn.cocoapods.org/']), 'Native SDK must resolve from public CocoaPods'
else:
    run('flutter', 'build', 'apk', '--debug')
    result = subprocess.check_output(['./gradlew', ':app:dependencyInsight', '--dependency', 'com.pushplatform:sdk-android', '--configuration', 'debugRuntimeClasspath', '--console=plain'], cwd=consumer / 'android', text=True)
    native = re.search(r'com.pushplatform:sdk-android:([^"\s]+)', (root / 'android/build.gradle.kts').read_text())[1]
    assert f'com.pushplatform:sdk-android:{native}' in result, 'Wrong Maven version'
    print(result)
print(f'Consumer build passed: Flutter {version}, {args.platform}, published={args.published}')
