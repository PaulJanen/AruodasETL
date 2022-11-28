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
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.support.ui import Select
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.chrome.options import Options

import io
from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobClient
from azure.keyvault.secrets import SecretClient

chrome_options = Options()
chrome_options.add_argument('--no-sandbox')
chrome_options.add_argument('--headless')
chrome_options.add_argument('--disable-dev-shm-usage')
chrome_prefs = {}
chrome_options.experimental_options["prefs"] = chrome_prefs
chrome_prefs["profile.default_content_settings"] = {"images": 2}
driver = webdriver.Chrome(ChromeDriverManager().install(),options=chrome_options)
driver.execute_cdp_cmd('Network.setUserAgentOverride', {"userAgent": 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.53 Safari/537.36'})
driver.execute_script("Object.defineProperty(navigator, 'webdriver', {get: () => undefined})")


def GetDistrictUrl(city, district):
    url = "https://en.aruodas.lt/"   
    driver.get(url)
    sleep(1)   
    driver.find_element(By.ID, 'display_FRegion').click()
    sleep(0.5)
    cityInput = driver.find_element(By.ID, "filterInput_FRegion")
    cityInput.send_keys(city)
    sleep(0.5)
    cityInput.send_keys(Keys.ENTER)
    sleep(0.5)
    driver.find_element(By.ID, 'display_FQuartal').click()
    sleep(2)
    driver.switch_to.frame(driver.find_element(By.ID, "fancybox-frame"))
    sleep(1)
    driver.find_element(By.XPATH,"//label[@title='{}']".format(district)).click()
    sleep(0.5)
    driver.find_element(By.ID, 'btSaveSelected').click()
    sleep(0.5)
    driver.switch_to.default_content()
    sleep(0.5)
    driver.find_element(By.ID, 'buttonSearchForm').click()
    currentUrl = driver.current_url
    return currentUrl

def ConvertToKm(measurement):
    if(measurement == None):
        return nan

    if(re.search('km', measurement) == None): 
        return round((float)(measurement[:-1]) * 0.001,2)
    else:
        return round((float)(measurement[:-2]),2)

def GetDistrictPropertyData(districtUrl, city, district, globalDataFrame):
    #driver = webdriver.Chrome(ChromeDriverManager().install(),options=chrome_options)
    driver.get(districtUrl)
    sleep(5)
    #driver.find_element(By.ID,'onetrust-accept-btn-handler').click()
    sleep(1)
    
    soup = bs(driver.page_source, "lxml")
    pagination = soup.find("div", {"class" : "pagination"})
    maxPages = 1
    if(pagination is not None and len(pagination) > 0):
        maxPages = (len(pagination.find_all("a", {"class" : "page-bt"})))
    print(maxPages)
    for page in range(1,maxPages+1):
        url = districtUrl + "puslapis/" + str(page) + "/"       
        driver.get(url)
        sleep(5)
        soup = bs(driver.page_source, "lxml")
        allElements = soup.find("div", {"class" :"list-search-v2"})
        allElements = allElements.find_all("div", {"class" :"list-adress-v2"})
        allListings = [element.find('h3').find('a', href=True)['href'] for element in allElements if element.find('h3') != None]
        #allListings = [element for element in allElements if element.find("div", {"class":"list-adress-v2"}) != None]
        #print(allListings[0].prettify())
        for propertyUrl in allListings:
            driver.get(propertyUrl)
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
                                    ,'CrimeRate': [crimeRate],'City': [city], 'District': [district], 'href':[propertyUrl]})
            globalDataFrame = pd.concat( [globalDataFrame, dataTable])
            #print(globalDataFrame)
            driver.back()
            sleep(1)        
    return globalDataFrame


def GetAllListings(flatsPriceData):
    global globalDataFrame

    url = "https://en.aruodas.lt/"   
    driver.get(url)
    sleep(1)
    driver.find_element(By.ID, 'onetrust-accept-btn-handler').click()
    sleep(1)

    for index in range(0,flatsPriceData.shape[0]):
        districtUrl = GetDistrictUrl(flatsPriceData.iloc[index][0], flatsPriceData.iloc[index][1])
        globalDataFrame = GetDistrictPropertyData(districtUrl, flatsPriceData.iloc[index][0], flatsPriceData.iloc[index][1], globalDataFrame)
    return globalDataFrame


def ChangeDataTypesAndCleanData(df):
    df = df.reset_index()
    df["Price"] = pd.to_numeric(df["Price"])
    df["PricePerM2"] = pd.to_numeric(df["PricePerM2"])
    df["Area"] = pd.to_numeric(df["Area"])
    df["floor"] = pd.to_numeric(df["floor"])
    df["Number of floors"] = pd.to_numeric(df["Number of floors"])
    df["Room count"] = pd.to_numeric(df["Room count"])
    df['Built year'] = df['Built year'].apply(lambda x: x[0:4])
    df["Built year"] = pd.to_datetime(df['Built year'].apply(lambda x: x[0:4]) + "-01-01")
    df["Equipment"] = df["Equipment"].apply(lambda x: "Partial decoration" if "USEFUL" in x else x)
    df["NearestKindergarten"] = pd.to_numeric(df["NearestKindergarten"])
    df["NearestEducational"] = pd.to_numeric(df["NearestEducational"])
    df["NearestShop"] = pd.to_numeric(df["NearestShop"])
    df["NearestStop"] = pd.to_numeric(df["NearestStop"])
    df["CrimeRate"] = pd.to_numeric(df["CrimeRate"])
    return df

dir_path = os.path.dirname(os.path.realpath(__file__))
os.chdir(dir_path)
flatsPriceData = pd.read_csv("FlatsPriceData.csv")
city = os.environ.get("City")
filter = flatsPriceData["City"] == city
flatsPriceData = flatsPriceData[filter]

globalDataFrame = pd.DataFrame()
allListings = GetAllListings(flatsPriceData)
#allListings = ChangeDataTypesAndCleanData(allListings)
allListings = allListings.reset_index(drop=True)

df = pd.DataFrame()
df['date2'] = pd.to_datetime(allListings['Built year'].apply(lambda x: x[0:4]) + "-01-01", errors = 'coerce')
df = df.reset_index(drop=True)
indexesForCleaning = df.loc[df['date2'].isna()].index.array
indexesForCleaning

for index in indexesForCleaning:
    indexesForCleaning = df.loc[df['date2'].isna()].index.array
    cityForCleaning = allListings['City'].iloc[index]
    districtForCleaning = allListings['District'].iloc[index]
    withoutProblematicDates = allListings[~allListings.index.isin(indexesForCleaning)]
    filter1 = withoutProblematicDates['City'] == cityForCleaning
    filter2 = withoutProblematicDates['District'] == districtForCleaning

    withoutProblematicDates = withoutProblematicDates.loc[filter1 * filter2]
    dates = pd.to_datetime(withoutProblematicDates['Built year'].apply(lambda x: x[0:4]) + "-01-01")
    medianDate = int(np.median(np.array(dates.map(dt.datetime.toordinal))))
    medianDate = dt.datetime.fromordinal(medianDate)
    year = str(medianDate)[0:4]
    allListings["Built year"].iloc[index] = year


BLOB_account = 'acountb'
BLOB_container = 'testcontainer'
BLOB_name = 'AllEligibleListings' + "Unclean" + city + '.csv'
KV_account = 'AruodasEtlKeys'
KV_secret_name = 'testsecret'
AZ_credential = DefaultAzureCredential()
KV_url = f'https://{KV_account}.vault.azure.net'
KV_secretClient = SecretClient(vault_url=KV_url, credential=AZ_credential)
BLOB_PrimaryKey = KV_secretClient.get_secret(KV_secret_name).value

BLOB_CONN_STR = f'DefaultEndpointsProtocol=https;AccountName={BLOB_account};AccountKey={BLOB_PrimaryKey};EndpointSuffix=core.windows.net'
BLOB_client = BlobClient.from_connection_string(conn_str=BLOB_CONN_STR, container_name=BLOB_container, blob_name=BLOB_name)
allListings.to_csv('AllEligibleListings' + "Unclean" + city + '.csv', index=False, encoding='utf-8-sig')

with open('AllEligibleListings' + "Unclean" + city + '.csv', 'rb') as f:
    dataBytesBuffer = io.BytesIO(f.read())
    dataBytesBuffer.seek(0)
    BLOB_client.upload_blob(dataBytesBuffer, overwrite=True)
    print(f'File successfully uploaded to blob')



allListings = ChangeDataTypesAndCleanData(allListings)
#allListings.to_csv('./Output/AllListings.csv', index=False, encoding='utf-8-sig')


pd.set_option('display.max_rows', 10)
allListingsCount = (allListings.groupby(['City', 'District']).size().reset_index(name='ListingsCount'))
eligibleListings = allListingsCount[allListingsCount["ListingsCount"]>=20].reset_index(drop=True)
#eligibleListings.to_csv('./Output/EligibleListings.csv', index=False, encoding='utf-8-sig')

allEligiblePropertiesFilter = allListings["District"].apply(lambda x: True if x in eligibleListings["District"].array else False)
allEligibleListings = allListings[allEligiblePropertiesFilter].drop("index", axis = 1)
allEligibleListings.to_csv('AllEligibleListings' + city + '.csv', index=False, encoding='utf-8-sig')
driver.close()


BLOB_account = 'acountb'
BLOB_container = 'testcontainer'
BLOB_name = 'AllEligibleListings' + city + '.csv'
KV_account = 'AruodasEtlKeys'
KV_secret_name = 'testsecret'
AZ_credential = DefaultAzureCredential()
KV_url = f'https://{KV_account}.vault.azure.net'
KV_secretClient = SecretClient(vault_url=KV_url, credential=AZ_credential)
BLOB_PrimaryKey = KV_secretClient.get_secret(KV_secret_name).value

BLOB_CONN_STR = f'DefaultEndpointsProtocol=https;AccountName={BLOB_account};AccountKey={BLOB_PrimaryKey};EndpointSuffix=core.windows.net'
BLOB_client = BlobClient.from_connection_string(conn_str=BLOB_CONN_STR, container_name=BLOB_container, blob_name=BLOB_name)
with open('AllEligibleListings' + city + '.csv', 'rb') as f:
    dataBytesBuffer = io.BytesIO(f.read())
    dataBytesBuffer.seek(0)
    BLOB_client.upload_blob(dataBytesBuffer, overwrite=True)
    print(f'File successfully uploaded to blob')