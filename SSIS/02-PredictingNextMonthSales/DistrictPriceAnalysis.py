from sklearn.linear_model import LinearRegression
from sklearn.preprocessing import PolynomialFeatures
from matplotlib import pyplot as plt
from dateutil import rrule

import matplotlib.dates as mdates
import matplotlib


import pandas as pd
import numpy as np
import datetime as dt
from datetime import datetime
import os
import sys


def GetPredictedPriceTable(eligibleLocations, data, priceColumnName, predictionDate, drawTimeSeries = False):
    predictedPriceTable = pd.DataFrame(columns = ["City","District",priceColumnName])
    for city in set(eligibleLocations["City"]): 
        for district in set(eligibleLocations[eligibleLocations["City"] == city]["District"]):
            df2 = MakeLoactionPredictions(data, city, district, priceColumnName, drawTimeSeries)
            predictedPriceTable = pd.concat([df2, predictedPriceTable])
    return predictedPriceTable


def MakeLoactionPredictions(data, city, district, priceColumnName, drawTimeSeries):
    filter1 = data["City"] == city
    filter2 = data["District"] == district
    df = data[filter1*filter2]
    df = RejectOutliersUsingMean(df)
    
    x = np.array(df['Date'].map(dt.datetime.toordinal)).reshape((-1, 1))
    y = np.array(df['Price'])
    poly = PolynomialFeatures(degree=1, include_bias=False)
    poly_features = poly.fit_transform(x)
    model = LinearRegression()
    model = LinearRegression().fit(poly_features, y)
    r_sq = model.score(poly_features, y)
    #print(f"coefficient of determination: {r_sq}")
    predictionDay = pd.to_datetime(predictionDate).toordinal()
    predictedPrice = model.predict(poly.fit_transform(np.array(predictionDay).reshape((-1, 1))))
    df2 = pd.DataFrame([[city,district,predictedPrice[0]]], columns=['City','District',priceColumnName])
    
    yPredicted = model.predict(poly.fit_transform(np.sort(x,axis = 0)))
    if(drawTimeSeries):
        DrawTimeSeriesGraph(df, x, y, model, yPredicted)
    
    return df2

def DrawTimeSeriesGraph(df,x,y, model, yPredicted):
    start_date = df.sort_values(by="Date")["Date"].iloc[0]
    end_date = df.sort_values(by="Date")["Date"].iloc[-1]
    start_date = pd.to_datetime(start_date).toordinal()
    end_date = pd.to_datetime(end_date).toordinal()
    labelCount = 12 
    chunkSize = int((end_date-start_date)/labelCount)

    xLabels = []
    dateLabels = []
    for i in range(start_date,end_date,chunkSize):
        xLabels.append(i) 
        dateLabels.append(datetime.fromordinal(i).strftime('%Y-%m-%d'))    
    
    fig, ax = plt.subplots()#figsize=(10,10))
    plt.scatter(x, y,color='g')
    plt.plot(np.sort(x,axis = 0), yPredicted.reshape((-1, 1)),color='k')
    #plt.xticks(x.flatten(),df['Date'].dt.strftime('%Y-%m-%d').to_numpy().reshape((-1, 1)).flatten(), rotation=90)
    plt.xticks(xLabels,dateLabels, rotation=90)

    #every_nth = 1
    #for n, label in enumerate(ax.xaxis.get_ticklabels()):
    #    if (n % every_nth != 0 and n != 0 and n != len(ax.xaxis.get_ticklabels())):
    #        label.set_visible(False)

    #ax.tick_params(axis='x', which='major', labelsize=10)
    plt.show()


def RejectOutliersUsingMean(data):
    u = np.mean(data["Price"])
    s = np.std(data["Price"])
    data_filtered = data[(data["Price"]>(u-2*s)) & (data["Price"]<(u+2*s))]
    return data_filtered

def RejectOutliersUsingMedian(data):
    u = np.median(np.array(data["Price"]))
    s = np.quantile(np.array(data["Price"]), 0.85)
    data_filtered = data[(data["Price"]>(u-s)) & (data["Price"]<(u+s))]
    return data_filtered



dir_path = os.path.dirname(os.path.realpath(__file__))
os.chdir(dir_path)

eligibleFlatsForAnalysis = pd.read_csv('Input/EligibleFlatsForAnalysis.csv')

flatsForSaleData = pd.read_csv('Input/FlatsForSale.csv')
flatsForRentData = pd.read_csv('Input/FlatsForRent.csv')

flatsForSaleData["Date"] = pd.to_datetime(flatsForSaleData["Date"])
flatsForRentData["Date"] = pd.to_datetime(flatsForRentData["Date"])


#Finding currently most profitable flat, but as well find most profitable in the future

predictionDate = sys.argv[1]
priceColumnName = "FlatSalePricem2"
flatsForSalePredicted = GetPredictedPriceTable(eligibleFlatsForAnalysis, flatsForSaleData, priceColumnName, predictionDate)

priceColumnName = "FlatSalePricem2"
flatsForRentPredicted = GetPredictedPriceTable(eligibleFlatsForAnalysis, flatsForRentData, priceColumnName, predictionDate)


flatsPriceData = pd.merge(flatsForSalePredicted, flatsForRentPredicted, how="inner", on=["City","District"])
flatsPriceData.columns = ['City', 'District', 'Sale_m2', 'Rent_m2']
flatsPriceData["RelativePriceToRent"] = flatsPriceData["Sale_m2"]/flatsPriceData["Rent_m2"]
flatsPriceData = flatsPriceData.sort_values(by=['RelativePriceToRent'])
#The lower Relative Price is the better

flatsPriceData.to_csv('Output/FlatsPriceData.csv', index=False, encoding='utf-8-sig')