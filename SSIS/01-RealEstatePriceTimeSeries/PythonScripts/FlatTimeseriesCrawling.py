import getpass
import os
import sys

import re
import requests as req
from bs4 import BeautifulSoup as bs
import pandas as pd
from time import sleep
import getpass
from selenium import webdriver
from selenium.webdriver.support.ui import Select
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys

"""
try:
    input("Press Enter to continue...")
except SyntaxError:
    pass

print("Type email:")

email = input()

print("Type psw:")
pswd = getpass.getpass('Password:')

input("Press Enter to print email")

print(email)

input("Press Enter to print psw")

print(pswd)

input("Press Enter to print arguments")

for inputval in sys.argv[1:]:
    print (inputval)

input("Press Enter to exit")

"""

def OpenAndPrepareSite(email, pswd):
    url = "https://en.aruodas.lt/kainu-statistika/"
    driver = webdriver.Chrome(r"C:/Users/paulius.janenas/Documents/GitHub\AruodasETL/SSIS/RealEstatePriceTimeSeries/PythonScripts/chromedriver.exe")
    driver.get(url)
    sleep(1)
    driver.find_element(By.ID, 'onetrust-accept-btn-handler').click()
    sleep(1)
    driver.find_element(By.CLASS_NAME, 'submit').click()
    sleep(1)
    username = driver.find_element(By.ID, "userName")
    username.send_keys(email)
    password = driver.find_element(By.ID, "password")
    password.send_keys(pswd)
    driver.find_element(By.ID,'loginAruodas').click()
    return driver

def GetPropertyTypeTimeseries(propertyType, driver):
    sleep(1)
    elementDropdown = driver.find_element(By.NAME,"type[0]")
    select = Select(elementDropdown)
    select.select_by_visible_text(propertyType)
    sleep(0.1)

    globalDataFrame = pd.DataFrame()
    #regions = ["Vilnius","Kaunas","Klaipėda","Šiauliai","Panevėžys","Alytus","Palanga"]
    regions = ["Palanga"]
    for region in regions:
        elementDropdown = driver.find_element(By.NAME,"region[0]")
        select = Select(elementDropdown)
        select.select_by_visible_text(region)
        sleep(0.5)

        elementDropdown = driver.find_element(By.NAME,"quartal[0]")
        select = Select(elementDropdown)
        allDistricts = [item.text for item in select.options]
        sleep(0.5)
        for i in range(1,len(allDistricts)):
            districtName = allDistricts[i]
            elementDropdown = driver.find_element(By.NAME,"quartal[0]")
            select = Select(elementDropdown)
            select.select_by_visible_text(districtName)
            sleep(0.1)

            #set date period
            elementDropdown = driver.find_element(By.NAME,"statsyearfrom")
            select = Select(elementDropdown)
            select.select_by_visible_text("2017")
            sleep(0.1)
            elementDropdown = driver.find_element(By.NAME,"statsmonthfrom")
            select = Select(elementDropdown)
            select.select_by_visible_text("January")
            
            driver.find_element(By.CLASS_NAME, 'submit').click()
            sleep(2.5)

            dataTable = GetAllTableElements(driver)
            if(type(dataTable) is pd.core.frame.DataFrame):
                dataTable["Region"] = region
                dataTable["District"] = districtName
                globalDataFrame = pd.concat( [globalDataFrame, dataTable])
    return globalDataFrame 

def GetAllTableElements(driver):
    try:
        page_source = driver.page_source
    except:
        print("Empty table")
        return None
    soup = bs(page_source, 'html.parser')
    table = soup.find("div", {"id" : "price-statistics-table"})
    #table = table.find('table')
    rows = table.find_all('tr')
    data = []
    for row in rows:
        cols = row.find_all('td')
        cols = [ele.text.strip() for ele in cols]
        data.append([ele for ele in cols if ele])
    
    col1 = [item[0] for item in data]
    col2 = [item[1] for item in data]
    if(len(col1) == 0 or len(col2) == 0):
        print("Empty list")
        return None
    dataTable = pd.DataFrame(zip(col1[1:],col2[1:]), columns = [col1[0],"Price"])
    return dataTable

def CrawlData(propertyType, tableName):
    dir_path = os.path.dirname(os.path.realpath(__file__))
    os.chdir(dir_path)

    print("Type aruodas email:")
    email = "murkuzas1@gmail.com"#input()
    print("Type psw:")
    pswd = getpass.getpass('Password:')

    driver = OpenAndPrepareSite(email, pswd)
    propertyType = propertyType
    dataTable =  GetPropertyTypeTimeseries(propertyType, driver)

    os.chdir("../Output")
    dataTable.to_csv(tableName,index=False)

CrawlData(sys.argv[2], sys.argv[1])

#for inputval in sys.argv[1:]:
#    print(inputval)

#input("Press Enter to print arguments")
#os.chdir('/tmp')


