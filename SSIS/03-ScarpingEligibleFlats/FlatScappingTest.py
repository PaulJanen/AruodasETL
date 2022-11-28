import requests as req
from bs4 import BeautifulSoup as bs
import pandas as pd
import re
import numpy as np
from numpy import nan
import datetime as dt
from datetime import datetime
import os

from time import sleep
from selenium import webdriver
from selenium.webdriver.support.ui import Select
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys

def ConvertToKm(measurement):
    if(measurement == None):
        return nan

    if(re.search('km', measurement) == None): 
        return round((float)(measurement[:-1]) * 0.001,2)
    else:
        return round((float)(measurement[:-2]),2)

def GetDistrictPropertyData(propertyUrl, city, district):
    driver = webdriver.Chrome(r"../chromedriver.exe")
    driver.get(propertyUrl)
    sleep(1)
    driver.find_element(By.ID,'onetrust-accept-btn-handler').click()
    sleep(1)
    soup = bs(driver.page_source, "lxml")
    
    price = soup.find("span", {"class" : "price-eur"}).text.split("€")[0].strip().replace(" ", "")
    pricePerM2 = soup.find("span", {"class" : "price-per"}).text.split("€")[0].strip().split("(")[1].replace(" ", "")         
    
    mainTable = soup.find("dl", {"class" : "obj-details"})
    area = mainTable.find('dt', text=re.compile('Area')).find_next_sibling('dd').text.strip().split(" ")[0].replace(",", ".")    
    floor = mainTable.find('dt', text=re.compile('Floor')).find_next_sibling('dd').text.strip()
    numberOfFloors = mainTable.find('dt', text=re.compile('No. of floors')).find_next_sibling('dd').text.strip()
    roomCount = mainTable.find('dt', text=re.compile('Number of rooms')).find_next_sibling('dd').text.strip()
    builtYear = mainTable.find('dt', text=re.compile('Build year')).find_next_sibling('dd').text.strip()
    heating = mainTable.find('dt', text=re.compile('Heating system')).find_next_sibling('dd').text.strip()
    equipment = mainTable.find('dt', text=re.compile('Equipment')).find_next_sibling('dd').text.strip()

    nearestObj = soup.find_all("div", {"class" : "statistic-info-cell-main"})
    nearestKindergarten = [item.find("span",  {"class" : "cell-data"}).text for item in nearestObj if item.find("span", {"class" : "cell-text"}).text == 'Nearest kindergarten ']
    nearestKindergarten = None if(len(nearestKindergarten) == 0) else nearestKindergarten[0].replace(' ', '').replace('\n', '')[1:].replace(",", ".") 
    nearestEducational = [item.find("span",  {"class" : "cell-data"}).text for item in nearestObj if item.find("span", {"class" : "cell-text"}).text == 'Nearest educational institution']
    nearestEducational = None if(len(nearestEducational) == 0) else nearestEducational[0].replace(' ', '').replace('\n', '')[1:].replace(",", ".")
    nearestShop = [item.find("span",  {"class" : "cell-data"}).text for item in nearestObj if item.find("span", {"class" : "cell-text"}).text == 'Nearest shop']
    nearestShop = None if(len(nearestShop) == 0) else nearestShop[0].replace(' ', '').replace('\n', '')[1:].replace(",", ".")
    nearestStop = [item.find("span",  {"class" : "cell-data"}).text for item in nearestObj if item.find("span", {"class" : "cell-text"}).text == 'Public transport stop']
    nearestStop = None if(len(nearestStop) == 0) else nearestStop[0].replace(' ', '').replace('\n', '')[1:].replace(",", ".")
    crimeRateSoup = soup.find_all("div", {"class" : "arrow_line_left"})
    
    crimeRate = None
    for i, crime in enumerate(crimeRateSoup):
        if(crimeRateSoup[i].find("div", {"class" : "icon-crime-gray"}) != None):
            crimeRate = crimeRateSoup[i].find("span", {"class" : "cell-data"}).text

    dataTable = pd.DataFrame({'Price': [price], 'PricePerM2': [pricePerM2], 'Area': [area], 'floor' : [floor], 'Number of floors': [numberOfFloors], 'Room count': [roomCount]
                            ,'Built year': [builtYear], 'Heating': [heating], 'Equipment': [equipment],'NearestKindergarten': [ConvertToKm(nearestKindergarten)]
                            ,'NearestEducational': [ConvertToKm(nearestEducational)],'NearestShop': [ConvertToKm(nearestShop)],'NearestStop': [ConvertToKm(nearestStop)]
                            ,'CrimeRate': [crimeRate],'City': [city], 'District': [district]})
     
    driver.close()
    return dataTable



dir_path = os.path.dirname(os.path.realpath(__file__))
os.chdir(dir_path)

allListings = GetDistrictPropertyData('https://en.aruodas.lt/butai-siauliuose-centre-draugystes-pr-parduodamas-labai-geroje-vietoje-gerai-1-3272862/', "Siauliai", "centras")

print(allListings)
