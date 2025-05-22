import pytest
import sys
import os

# Add parent directory to path so we can import main
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from main import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_hello_endpoint(client):
    response = client.get('/')
    assert response.status_code == 200
    data = response.get_json()
    assert 'message' in data
    assert data['message'] == 'Hello from Python API!'

def test_health_endpoint(client):
    response = client.get('/health')
    assert response.status_code == 200
    data = response.get_json()
    assert data['status'] == 'healthy'

def test_users_endpoint(client):
    response = client.get('/api/users')
    assert response.status_code == 200
    data = response.get_json()
    assert len(data) == 2
    assert data[0]['name'] == 'John Doe'
