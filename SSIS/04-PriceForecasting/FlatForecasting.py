import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

import scipy.stats as st
import scipy.stats as stats
import sklearn.linear_model as linear_model
from sklearn.linear_model import LinearRegression
from sklearn import preprocessing
#import seaborn as sns

import tensorflow as tf
from tensorflow import keras
from keras import Sequential
from keras.layers import Dense

import datetime as dt
from datetime import datetime
import os
import sys



def CreateOutput(fileName, model):
    pricePrediction = data
    X = pd.get_dummies(data=pricePrediction[[*qualitative]], drop_first=True).values
    X = np.append(X, preprocessing.normalize(pricePrediction[[*quantitative]]), axis=1)
    predictedPrice = model.predict(X).flatten()
    actualPrice = data.Price
    predictedLosses = actualPrice - predictedPrice
    pricePrediction["Losses"] = predictedLosses
    pricePrediction["PredictedPrice"] = predictedPrice
    pricePrediction = pricePrediction.sort_values(by=['Losses'])
    pricePrediction["Year Built"] = pricePrediction["Built year"].apply(lambda x: datetime.fromordinal(x).strftime('%Y-%m-%d'))
    pricePrediction = pricePrediction.drop("Built year", axis = 1)
    pricePrediction["ScrapingDate"] = sys.argv[1]
    pricePrediction.to_csv('./Output/'+ fileName, index=False, encoding='utf-8-sig')


dir_path = os.path.dirname(os.path.realpath(__file__))
os.chdir(dir_path)

filepaths = ["Input/"+f for f in os.listdir("Input") if f.endswith('.csv')]
data = pd.concat(map(pd.read_csv, filepaths))
data["Built year"] = pd.to_datetime(data["Built year"]).map(dt.datetime.toordinal)

train=data.sample(frac=1,random_state=200) #random state is a seed value
test=data.drop(train.index)
quantitative = [f for f in train.columns if train.dtypes[f] != 'object']
quantitative.remove('Price')
quantitative.remove('PricePerM2')
quantitative.remove('NearestKindergarten')
quantitative.remove('NearestEducational')
quantitative.remove('NearestShop')
quantitative.remove('NearestStop')
quantitative.remove('CrimeRate')

qualitative = [f for f in train.columns if train.dtypes[f] == 'object']
qualitative.remove('href')

print(qualitative)

missing = train.isnull().sum()
#print(missing) ## No missing data detected

x = pd.get_dummies(data=train[[*quantitative,*qualitative]], drop_first=True).values
y = train['Price'].values
model = LinearRegression()
model = LinearRegression().fit(x, y)
r_sq = model.score(x, y)

CreateOutput('FlatForecastLinearRegression.csv', model)


modelNN = Sequential()
modelNN.add(Dense(74, activation='relu', kernel_initializer='HeNormal'))
modelNN.add(Dense(100, activation='relu', kernel_initializer='HeNormal'))
modelNN.add(Dense(100, activation='relu', kernel_initializer='HeNormal'))
modelNN.add(Dense(50, activation='relu', kernel_initializer='HeNormal'))
modelNN.add(Dense(1))

modelNN.compile(loss='mean_squared_error', optimizer='adam')
X = pd.get_dummies(data=train[[*qualitative]], drop_first=True).values
X = np.append(X, preprocessing.normalize(train[[*quantitative]]), axis=1)
Y = train['Price'].values


pd.options.display.max_rows = 10
# Train the model
modelNN.fit(
    X,
    Y,
    epochs=10000
);

CreateOutput('FlatForecastNN.csv', modelNN)
