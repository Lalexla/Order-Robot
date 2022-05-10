from pickle import TRUE
from tkinter import Image
from RPA.Browser.Selenium import Selenium
from selenium import webdriver
from selenium.webdriver import ActionChains
from fpdf import FPDF

import urllib.request
import csv
import time
 

browser_lib = Selenium()
driver = webdriver.Chrome()
my_url = "https://robotsparebinindustries.com/#/robot-order"
driver.get(my_url)
pdf = FPDF()

def check_existance(id):
    if driver.find_element_by_id(id):
        return True
    else:
        return False

def get_orders():
    table = urllib.request.urlretrieve("https://robotsparebinindustries.com/orders.csv", "orders.csv")   
    return table

def robot_snapshot(row_data):
    button = driver.find_element_by_id("Preview")
    ActionChains(driver).click(button).perform()
    time.sleep(0.5)
    robo_pre = driver.find_element_by_id("robot-preview-image")
    return robo_pre.screenshot_as_png('order_' + row_data + '.png')
    

def close_modal():
    button = driver.find_element_by_id("OK")
    ActionChains(driver).click(button).perform()

def open_site(url):
    browser_lib.open_available_browser(url)

def submit_order():
    button = driver.find_element_by_id("Order")
    ActionChains(driver).click(button).perform()
    time.sleep(0.5)
    if check_existance("order-another"):
        pass
    else:
        ActionChains(driver).click(button).perform()

def order_another():
    ActionChains(driver).click("order-another").perform()

def fill_form(row_data):
    input_field = "css:input"
    #browser_lib.input_text(input_field, row_data[Head])
    #build inputs
    driver.find_element_by_css_selector("input[type='radio'][value='']").click()


def save_as_pdf(order, robo_img):
    img1 = Image.open(robo_img)
    emb_img = img1.convert('RGB')
    # build embeding
    pdf.output(order + ".pdf")

def create_receipt_zip():
    #build receipt zip
    pass

def main():
    try:
        open_site(my_url)
        table = get_orders()
        csv_reader = csv.reader(table, delimiter=',')
        for row in csv_reader:
            close_modal()
            fill_form(row)
            robo_image = robot_snapshot(row)
            submit_order()
            save_as_pdf(row, robo_image)
            order_another()                 
    finally:
        create_receipt_zip()
        browser_lib.close_all_browsers()
