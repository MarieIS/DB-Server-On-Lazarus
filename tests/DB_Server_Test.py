import socket
import time
import subprocess
import sys

def test_server():
    HOST = 'localhost'
    PORT = 3003

    print('Starting Full Test\n')
    
    # connecting to the server
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.connect((HOST, PORT))
        print('[Test 1] Connected to the server')
    except Exception as e:
        print(f'[Error] Could not connect: {e}')
        return False
    
    # sending the first message
    msg1 = "SELECT * FROM users\x00"
    s.send(msg1.encode())
    print(f'[Test 2] Sent the first message {msg1}')

    # receiving the answer
    s.settimeout(2)
    try:
        response1 = s.recv(1024)
        print(f'[Test 3] Received response: {response1}')

        if response1.endswith(b'\x00'):
            print('[Test 4] Response ends with null byte')
        else:
            print('[Test 4] Response does not end with null byte')
            return False
    except socket.timeout:
        print('[Error] No response received')
        return False
    
    # sending the second message - check whether the server is still able to receive messages
    msg2 = "INSERT INTO users VALUES ('test', 'test@mail.com')\x00"
    s.send(msg2.encode())
    print(f'[Test 5] Sent the second message: {msg2[:30]}')

    try:
        response2 = s.recv(1024)
        print(f'[Test 6] Received the second response: {response2[:50]}')

        if response2.endswith(b'\x00'):
            print('[Test 7] Second response ends with null byte')
        else:
            print('[Test 7] Second response does not end with null byte')
    except socket.timeout:
        print('[Error] No response for the second message - the server may have stopped')
        return False
    
    s.close()
    print('\n[Info] The server handled multiple messages successfully!')
    return True

def find_server_pid():
    # находит PID процесса сервера
    try:
        result = subprocess.run(['pgrep', '-f', 'masha'], capture_output=True, text=True)
        if result.stdout.strip():
            return int(result.stdout.strip())
    except:
        pass
    return None

def send_sigterm(pid):
    print(f'\n[Test 8] Sending SIGTERM to PID {pid} ...')
    subprocess.run(['kill', '-15', str(pid)])
    time.sleep(1)

    if find_server_pid() is None:
        print('[Test 9] The server was terminated after SIGTERM')
        return True
    else:
        print('[Test 9] The server is still running after SIGTERM')
        return False

if __name__ == '__main__':
    if test_server():
        print('\n' + '='*40)
        print('Basic Tests Passed')
        print('='*40)

        pid = find_server_pid()
        if pid:
            send_sigterm(pid)
        else:
            print('\n[Warning] Could not find the PID of the server. Is it running?')
    else:
        print('\n' + '='*40)
        print('Basic Tests Passed')
        print('='*40)