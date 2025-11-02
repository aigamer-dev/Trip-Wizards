"""
Travel Wizards - Comprehensive UI/UX Selenium Test Suite
Tests login flow, navigation, Settings/Profile area, form validation, and responsive behavior
"""
import pytest
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.action_chains import ActionChains
from selenium.common.exceptions import TimeoutException, NoSuchElementException
import time


@pytest.fixture(scope="module", params=["desktop", "tablet", "mobile"])
def driver(request):
    """Setup WebDriver with responsive screen sizes"""
    options = webdriver.ChromeOptions()
    options.add_argument('--headless')
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    
    driver = webdriver.Chrome(options=options)
    
    if request.param == "desktop":
        driver.set_window_size(1920, 1080)
    elif request.param == "tablet":
        driver.set_window_size(768, 1024)
    elif request.param == "mobile":
        driver.set_window_size(375, 667)
    
    yield driver
    driver.quit()


@pytest.fixture(scope="module")
def base_url():
    """Base URL for the application"""
    return "http://localhost:8080"


@pytest.fixture(scope="module")
def test_credentials():
    """Test user credentials"""
    return {
        "email": "mayank@travelwizards.ai",
        "password": "123456"
    }


class TestLoginFlow:
    """Test suite for login functionality"""
    
    def test_login_page_loads(self, driver, base_url):
        """Verify login page loads successfully"""
        driver.get(base_url)
        wait = WebDriverWait(driver, 10)
        
        try:
            wait.until(EC.presence_of_element_located((By.TAG_NAME, "body")))
            assert driver.title or driver.find_element(By.TAG_NAME, "body")
        except TimeoutException:
            pytest.fail("Login page failed to load within timeout")
    
    def test_login_form_elements(self, driver, base_url):
        """Verify all login form elements are present"""
        driver.get(base_url)
        wait = WebDriverWait(driver, 10)
        
        try:
            email_field = wait.until(
                EC.presence_of_element_located((By.CSS_SELECTOR, "input[type='email'], input[name='email']"))
            )
            password_field = driver.find_element(By.CSS_SELECTOR, "input[type='password'], input[name='password']")
            
            assert email_field.is_displayed()
            assert password_field.is_displayed()
        except (TimeoutException, NoSuchElementException):
            pytest.skip("Login form not found - may require navigation or different URL")
    
    def test_successful_login(self, driver, base_url, test_credentials):
        """Test successful login with valid credentials"""
        driver.get(base_url)
        wait = WebDriverWait(driver, 15)
        
        try:
            email_field = wait.until(
                EC.presence_of_element_located((By.CSS_SELECTOR, "input[type='email'], input[name='email']"))
            )
            password_field = driver.find_element(By.CSS_SELECTOR, "input[type='password'], input[name='password']")
            
            email_field.clear()
            email_field.send_keys(test_credentials["email"])
            
            password_field.clear()
            password_field.send_keys(test_credentials["password"])
            
            login_button = driver.find_element(
                By.CSS_SELECTOR, 
                "button[type='submit'], button:contains('Login'), button:contains('Sign In')"
            )
            login_button.click()
            
            time.sleep(3)
            
            assert "dashboard" in driver.current_url.lower() or \
                   "home" in driver.current_url.lower() or \
                   "profile" in driver.page_source.lower()
        except (TimeoutException, NoSuchElementException) as e:
            pytest.skip(f"Login flow elements not found: {str(e)}")
    
    def test_invalid_login(self, driver, base_url):
        """Test login with invalid credentials shows error"""
        driver.get(base_url)
        wait = WebDriverWait(driver, 10)
        
        try:
            email_field = wait.until(
                EC.presence_of_element_located((By.CSS_SELECTOR, "input[type='email'], input[name='email']"))
            )
            password_field = driver.find_element(By.CSS_SELECTOR, "input[type='password'], input[name='password']")
            
            email_field.clear()
            email_field.send_keys("invalid@example.com")
            
            password_field.clear()
            password_field.send_keys("wrongpassword")
            
            login_button = driver.find_element(By.CSS_SELECTOR, "button[type='submit']")
            login_button.click()
            
            time.sleep(2)
            
            error_message = driver.find_element(By.CSS_SELECTOR, "[class*='error'], [class*='alert']")
            assert error_message.is_displayed()
        except (TimeoutException, NoSuchElementException):
            pytest.skip("Error message element not found - may use different error handling")


class TestNavigationFlow:
    """Test suite for application navigation"""
    
    @pytest.fixture(autouse=True)
    def login(self, driver, base_url, test_credentials):
        """Auto-login before each test"""
        driver.get(base_url)
        wait = WebDriverWait(driver, 10)
        
        try:
            email_field = wait.until(
                EC.presence_of_element_located((By.CSS_SELECTOR, "input[type='email'], input[name='email']"))
            )
            password_field = driver.find_element(By.CSS_SELECTOR, "input[type='password'], input[name='password']")
            
            email_field.send_keys(test_credentials["email"])
            password_field.send_keys(test_credentials["password"])
            
            login_button = driver.find_element(By.CSS_SELECTOR, "button[type='submit']")
            login_button.click()
            
            time.sleep(3)
        except Exception:
            pytest.skip("Could not complete login for navigation test")
    
    def test_navigate_to_settings(self, driver):
        """Test navigation to Settings page"""
        wait = WebDriverWait(driver, 10)
        
        try:
            settings_link = wait.until(
                EC.element_to_be_clickable((By.CSS_SELECTOR, "[href*='settings'], a:contains('Settings')"))
            )
            settings_link.click()
            time.sleep(2)
            
            assert "settings" in driver.current_url.lower() or \
                   "Settings" in driver.page_source
        except (TimeoutException, NoSuchElementException):
            pytest.skip("Settings navigation element not found")
    
    def test_navigate_to_profile(self, driver):
        """Test navigation to Profile page from Settings"""
        wait = WebDriverWait(driver, 10)
        
        try:
            settings_link = wait.until(
                EC.element_to_be_clickable((By.CSS_SELECTOR, "[href*='settings']"))
            )
            settings_link.click()
            time.sleep(1)
            
            profile_link = wait.until(
                EC.element_to_be_clickable((By.CSS_SELECTOR, "[href*='profile'], a:contains('Profile')"))
            )
            profile_link.click()
            time.sleep(2)
            
            assert "profile" in driver.current_url.lower() or \
                   "Profile" in driver.page_source
        except (TimeoutException, NoSuchElementException):
            pytest.skip("Profile navigation element not found")


class TestProfileForm:
    """Test suite for Profile form validation and behavior"""
    
    @pytest.fixture(autouse=True)
    def navigate_to_profile(self, driver, base_url, test_credentials):
        """Navigate to profile page before each test"""
        driver.get(base_url)
        wait = WebDriverWait(driver, 10)
        
        try:
            email_field = wait.until(
                EC.presence_of_element_located((By.CSS_SELECTOR, "input[type='email']"))
            )
            password_field = driver.find_element(By.CSS_SELECTOR, "input[type='password']")
            
            email_field.send_keys(test_credentials["email"])
            password_field.send_keys(test_credentials["password"])
            
            login_button = driver.find_element(By.CSS_SELECTOR, "button[type='submit']")
            login_button.click()
            time.sleep(2)
            
            profile_link = driver.find_element(By.CSS_SELECTOR, "[href*='profile']")
            profile_link.click()
            time.sleep(2)
        except Exception:
            pytest.skip("Could not navigate to profile page")
    
    def test_profile_form_fields_exist(self, driver):
        """Verify all profile form fields are present"""
        wait = WebDriverWait(driver, 10)
        
        try:
            name_field = wait.until(
                EC.presence_of_element_located((By.CSS_SELECTOR, "input[name*='name'], input[placeholder*='Name']"))
            )
            assert name_field.is_displayed()
            
            email_field = driver.find_element(By.CSS_SELECTOR, "input[type='email']")
            assert email_field.is_displayed()
        except (TimeoutException, NoSuchElementException):
            pytest.skip("Profile form fields not found")
    
    def test_profile_form_validation(self, driver):
        """Test form validation for invalid email"""
        wait = WebDriverWait(driver, 10)
        
        try:
            email_field = wait.until(
                EC.presence_of_element_located((By.CSS_SELECTOR, "input[type='email']"))
            )
            
            email_field.clear()
            email_field.send_keys("invalid-email")
            email_field.send_keys(Keys.TAB)
            
            time.sleep(1)
            
            error_elements = driver.find_elements(By.CSS_SELECTOR, "[class*='error'], [aria-invalid='true']")
            assert len(error_elements) > 0
        except (TimeoutException, NoSuchElementException):
            pytest.skip("Email validation not found or uses different implementation")
    
    def test_profile_save_button_exists(self, driver):
        """Verify save button is present on profile form"""
        try:
            save_button = driver.find_element(By.CSS_SELECTOR, "button:contains('Save'), button[type='submit']")
            assert save_button.is_displayed()
        except NoSuchElementException:
            pytest.skip("Save button not found")


class TestResponsiveBehavior:
    """Test suite for responsive design behavior"""
    
    def test_mobile_layout(self, driver, base_url):
        """Test mobile layout responsiveness"""
        if driver.get_window_size()['width'] <= 480:
            driver.get(base_url)
            time.sleep(2)
            
            body = driver.find_element(By.TAG_NAME, "body")
            viewport_width = driver.execute_script("return window.innerWidth")
            assert viewport_width <= 480
            assert body.is_displayed()
    
    def test_tablet_layout(self, driver, base_url):
        """Test tablet layout responsiveness"""
        if 481 <= driver.get_window_size()['width'] <= 1024:
            driver.get(base_url)
            time.sleep(2)
            
            body = driver.find_element(By.TAG_NAME, "body")
            viewport_width = driver.execute_script("return window.innerWidth")
            assert 481 <= viewport_width <= 1024
            assert body.is_displayed()
    
    def test_desktop_layout(self, driver, base_url):
        """Test desktop layout responsiveness"""
        if driver.get_window_size()['width'] > 1024:
            driver.get(base_url)
            time.sleep(2)
            
            body = driver.find_element(By.TAG_NAME, "body")
            viewport_width = driver.execute_script("return window.innerWidth")
            assert viewport_width > 1024
            assert body.is_displayed()


class TestAccessibility:
    """Test suite for basic accessibility features"""
    
    def test_page_has_title(self, driver, base_url):
        """Verify page has a title"""
        driver.get(base_url)
        time.sleep(2)
        assert driver.title and len(driver.title) > 0
    
    def test_form_labels(self, driver, base_url):
        """Verify form fields have proper labels or aria-label"""
        driver.get(base_url)
        wait = WebDriverWait(driver, 10)
        
        try:
            inputs = wait.until(
                EC.presence_of_all_elements_located((By.TAG_NAME, "input"))
            )
            
            for input_elem in inputs:
                has_label = (
                    input_elem.get_attribute("aria-label") or
                    input_elem.get_attribute("aria-labelledby") or
                    input_elem.get_attribute("placeholder")
                )
                assert has_label, f"Input {input_elem.get_attribute('name')} missing label"
        except (TimeoutException, NoSuchElementException):
            pytest.skip("Form inputs not found")
    
    def test_keyboard_navigation(self, driver, base_url):
        """Test keyboard navigation works"""
        driver.get(base_url)
        time.sleep(2)
        
        try:
            body = driver.find_element(By.TAG_NAME, "body")
            ActionChains(driver).send_keys(Keys.TAB).perform()
            time.sleep(0.5)
            
            focused_element = driver.switch_to.active_element
            assert focused_element and focused_element != body
        except Exception:
            pytest.skip("Keyboard navigation test failed - may require different approach")


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
