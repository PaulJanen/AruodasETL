import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

import scipy.stats as st
import scipy.stats as stats
import sklearn.linear_model as linear_model
from sklearn.linear_model import LinearRegression
#import seaborn as sns

import datetime as dt
from datetime import datetime
import os

dir_path = os.path.dirname(os.path.realpath(__file__))
os.chdir(dir_path)

data = pd.read_csv('../03-ScarpingEligibleFlats/Output/AllEligibleListings.csv')
data["Built year"] = pd.to_datetime(data["Built year"]).map(dt.datetime.toordinal)

train=data.sample(frac=0.8,random_state=200) #random state is a seed value
test=data.drop(train.index)
quantitative = [f for f in train.columns if train.dtypes[f] != 'object']
quantitative.remove('Price')
qualitative = [f for f in train.columns if train.dtypes[f] == 'object']
qualitative.remove('href')