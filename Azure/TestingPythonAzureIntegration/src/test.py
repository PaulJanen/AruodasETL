import requests as req
from bs4 import BeautifulSoup as bs
import pandas as pd
import re
import numpy as np
from numpy import nan
import datetime as dt
from datetime import datetime
import os

dir_path = os.path.dirname(os.path.realpath(__file__))
os.chdir(dir_path)
flatsPriceData = pd.read_csv("FlatsPriceData.csv")
print(np.unique(flatsPriceData.City))