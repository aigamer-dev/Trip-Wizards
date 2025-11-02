import pytest
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
import time

@pytest.fixture(scope="module")
def driver():
    options = webdriver.ChromeOptions()
    options.add_argument('--headless')
    driver = webdriver.Chrome(options=options)
    yield driver
    driver.quit()

def test_login(driver):
    # Replace with your actual web app URL
    url = "http://localhost:8080/"
    driver.get(url)
    time.sleep(2)
    # Find and fill login fields
    driver.find_element(By.NAME, "email").send_keys("hariharan@aigamer.dev")
    driver.find_element(By.NAME, "password").send_keys("admin@123")
    driver.find_element(By.NAME, "password").send_keys(Keys.RETURN)
    time.sleep(3)
    # Check for successful login (update selector as needed)
    assert "dashboard" in driver.current_url or "profile" in driver.page_source
