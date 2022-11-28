Drop view if exists dataMart.FlatForecasting 
Go
Create View dataMart.FlatForecasting as
Select distinct flat.HK as FlatHK, HUB_CITY.HK as CityHK, HUB_EQUIPMENT.HK as EquipmentHK, flatHeating.HeatingHK as HeatingHK,
		SAT_FLAT.Price, SAT_FLAT.PredictedPrice, SAT_FLAT.Gains, flat.href from HUB_FLAT as flat
inner join LINK_FLATLOCATIONEQUIPMENT as locEq on flat.HK = locEq.FlatHK
inner join HUB_CITY on locEq.CityHK = HUB_CITY.HK
inner join HUB_EQUIPMENT on locEq.EquipmentHK = HUB_EQUIPMENT.HK
inner join LINK_FLATSHEATING as flatHeating on flat.HK = flatHeating.FlatHK
inner join SAT_FLAT on flat.HK = SAT_FLAT.HK



select * from dataMart.FlatForecasting

select *, PredictedPrice-Price from stage.AllListings where href = 'https://en.aruodas.lt/butai-palangoje-sventojoje-vilties-tak-parduodamas-2-kambariu-butas-sventojoje-1-3259578/'