
select *
from CovidDeaths
where total_cases is not null  or  continent is not null
order by date 


select top 10 *
from CovidDeaths
where total_cases is not null  and  total_deaths is not null
order by date 


select *
from CovidDeaths
where continent is not null 
order by 3, 4

select *
from CovidDeaths
where continent is not null 
order by location, date


-- Total Cases vs Total Deaths --
-- Showing the likeklihood of dying when contracted Covid per Country

select location, date, total_cases, total_deaths, round((cast(total_deaths as float)/cast(total_cases as float)),4)*100 as 'Death_Rate(%)'
from CovidDeaths
where total_cases >= '0'  and  continent is not null and location like '%kingdom%' 
order by location, date asc


-- Looking at Total Cases vs Population
-- Showing Percentage of Population infected with Covid

select location, date, population, total_cases, round((cast(total_cases as float)/cast(population as float)),4)*100 as 'Infection_Rate(%)'
from CovidDeaths
where population >= '0'  and  continent is not null and location like '%kingdom%'--or  total_deaths is not null
order by location, date 

-- Looking at Countries with Highest Infection Rate per Population

select	location, 
		population, 
		Max(total_cases) as Highest_Infection_Count, 
		round(
			max(
				cast(total_cases as float)/cast(population as float)
				)
			 ,4)*100 
			 as 'Max_Infection_Rate(%)'
from CovidDeaths
where population >= '0'  
	and  continent is not null -- and location like '%kingdom%'--or  total_deaths is not null
	and location not like '%world%' 
	and location not like '%income%'
	and location not like '%europe%'
	and location not like '%North America%'
	and location not like '%asia%'
	and location not like '%South America%'

group by location, population
order by 'Max_Infection_Rate(%)' desc


-- Looking at Countries with Highest Death Rate per Population

select	location, 
		population, 
		Max(cast(total_deaths as int)) as Highest_Death_Count, 
		round(
			max(
				cast(total_deaths as int)/cast(population as float)
				)
			 ,4)*100 
			 as 'Max_Death_Rate(%)'
from CovidDeaths
where population >= '0'  
	and  continent not like '' -- represents empty string ***LAZY to replace is not null above with not like ''****
/*	and location not like '%world%' 
	and location not like '%income%'
	and location not like '%europe%'
	and location not like '%North America%'
	and location not like '%asia%'
	and location not like '%South America%'
	*/
group by location, population
order by 'Highest_Death_Count' desc


-- Looking at Continents with Highest Death Rate 

select	continent, 
		Max(cast(total_deaths as int)) as Highest_Death_Count 
from CovidDeaths
where continent not like ''	-- use not like '' for empty string
group by continent
order by 'Highest_Death_Count' desc

-- The right answers to continent with highest rate is shown below--

select	location, 
		Max(cast(total_deaths as int)) as Highest_Death_Count 
from CovidDeaths
where continent like ''
group by location
order by 'Highest_Death_Count' desc


-- Showing continents with the highest death counts per population

select continent, --SUM(MAX(population)), 
		Max(cast(total_deaths as int)) as Highest_Death_Count 
from CovidDeaths
where continent not like ''	-- use not like '' for empty string
group by continent
order by 'Highest_Death_Count' desc


-- GLOBAL NUMBERS

-- per day
select date, 
	SUM(cast(new_cases as int)) as Global_Total_Case, 
	SUM(cast(new_deaths as int)) as Global_Deaths, 
	round(SUM(cast(new_deaths as float))/SUM(cast(new_cases as float)),4)*100 as Global_PercentageDeath
from CovidDeaths
where new_cases >= '0'  and  continent not like '' 
group by date
order by 1, 2 asc

--in total
select SUM(cast(new_cases as int)) as Global_Total_Case, 
	SUM(Convert(int, new_deaths)) as Global_Deaths, --Another way to  convert string/text to int
	round(SUM(cast(new_deaths as float))/SUM(cast(new_cases as float)),4)*100 as Global_PercentageDeath
from CovidDeaths
where new_cases >= '0'  and  continent not like '' 
--group by date
order by 1, 2 asc


--Looking at Total Population vs Vaccinations

-- 1st we need to joing the tables
/**** Joining the Two tables together ****/

select *
from CovidDeaths dea
join CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date


select	dea.continent, 
		dea.location, 
		dea.date, 
		dea.population, 
		vac.new_vaccinations, 
		SUM(convert(bigint, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated -- this sum location by location
		(RollingPeopleVaccinated/population) *100 --this gives an rttot message for using a column from a column. To solve this, we use CTE
from CovidDeaths dea
join CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where new_cases >= '0'  and  dea.continent not like '' 
group by dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations 
order by 1, 2, 3

-- USE CTE (common table expressions)

with PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
select	dea.continent, 
		dea.location, 
		dea.date, 
		dea.population, 
		vac.new_vaccinations, 
		SUM(convert(bigint, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated -- this sum location by location
		--(RollingPeopleVaccinated/population)*100
from CovidDeaths dea
join CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where new_cases >= '0'  and  dea.continent not like '' 
group by dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations 
--order by 1, 2, 3
)

select *, round(cast(RollingPeopleVaccinated as float)/cast(population as float),4)*100 as '%_RollingPeopleVaccinated'
from PopvsVac


--TEMP TABLE - finding the maximum percentage of the population that is vaccinated

drop table if exists #PercentPopulationVaccinated

Create Table #PercentPopulationVaccinated
(
continent nvarchar (255),
location nvarchar (255),
--date date,
population nvarchar (255),
New_vaccinations nvarchar (255),
RollingPeopleVaccinated nvarchar (255)
)

insert into #PercentPopulationVaccinated
select	dea.continent, 
		dea.location, 
		--dea.date, 
		dea.population, 
		vac.new_vaccinations, 
		SUM(convert(bigint, vac.new_vaccinations)) over (partition by dea.location order by dea.location/*, dea.date*/) as RollingPeopleVaccinated -- this sum location by location
		--(RollingPeopleVaccinated/population)*100
from CovidDeaths dea
join CovidVaccinations vac
	on dea.location = vac.location
	--and dea.date = vac.date
where new_cases >= '0'  and  dea.continent not like '' 
group by dea.continent, dea.location, /*dea.date,*/ dea.population, vac.new_vaccinations 
--order by 1, 2, 3

select *, round(cast(RollingPeopleVaccinated as float)/cast(population as float),4)*100 as '%_RollingPeopleVaccinated'
from #PercentPopulationVaccinated



-- Creating View to Store Data for later Visualizations
-- Creating view for PercentPopulationVaccinated

Create view PercentPopulationVaccinated as
select	dea.continent, 
		dea.location, 
		dea.date, 
		dea.population, 
		vac.new_vaccinations, 
		SUM(convert(bigint, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated -- this sum location by location
		--(RollingPeopleVaccinated/population)*100
from CovidDeaths dea
join CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where new_cases >= '0'  and  dea.continent not like '' 
group by dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations 
--order by 1, 2, 3


select *
from PercentPopulationVaccinated  -- is permanently created and can be viewed in the view table


-- Creating view for GEN_PercentPopulationVaccinated - no date

Create view GEN_PercentPopulationVaccinated as
select	dea.continent, 
		dea.location, 
		dea.population, 
		vac.new_vaccinations, 
		SUM(convert(bigint, vac.new_vaccinations)) over (partition by dea.location order by dea.location) as RollingPeopleVaccinated -- this sum location by location
		--(RollingPeopleVaccinated/population)*100
from CovidDeaths dea
join CovidVaccinations vac
	on dea.location = vac.location
where new_cases >= '0'  and  dea.continent not like '' 
group by dea.continent, dea.location, dea.population, vac.new_vaccinations 
--order by 1, 2, 3

select *
from GEN_PercentPopulationVaccinated  -- is permanently created and can be viewed in the view table


-- Creating view for GlobalPercentageDeath - no date

Create view GlobalPercentageDeath as
select SUM(cast(new_cases as int)) as Global_Total_Case, 
	SUM(Convert(int, new_deaths)) as Global_Deaths, --Another way to  convert string/text to int
	round(SUM(cast(new_deaths as float))/SUM(cast(new_cases as float)),4)*100 as Global_PercentageDeath
from CovidDeaths
where new_cases >= '0'  and  continent not like '' 
--group by date
--order by 1, 2 asc



-- Creating view for Incremental_GlobalPercentageDeath - no date

Create view Incremental_GlobalPercentageDeath as
select date, 
	SUM(cast(new_cases as int)) as Global_Total_Case, 
	SUM(cast(new_deaths as int)) as Global_Deaths, 
	round(SUM(cast(new_deaths as float))/SUM(cast(new_cases as float)),4)*100 as Global_PercentageDeath
from CovidDeaths
where new_cases >= '0'  and  continent not like '' 
group by date
--order by 1, 2 asc


-- Creating view for DeathCountPerContinent

Create view DeathCountPerContinent as
select continent, --SUM(MAX(population)), 
		Max(cast(total_deaths as int)) as Highest_Death_Count 
from CovidDeaths
where continent not like ''	-- use not like '' for empty string
group by continent
--order by 'Highest_Death_Count' desc


-- Creating view for DeathCountGlobal

Create view DeathCountGlobal as
select	location, 
		Max(cast(total_deaths as int)) as Highest_Death_Count 
from CovidDeaths
where continent like ''
group by location
--order by 'Highest_Death_Count' desc


-- Creating view for DeathRatePerCountry

Create view DeathRatePerCountry as
select	location, 
		population, 
		Max(cast(total_deaths as int)) as Highest_Death_Count, 
		round(
			max(
				cast(total_deaths as int)/cast(population as float)
				)
			 ,4)*100 
			 as 'Max_Death_Rate(%)'
from CovidDeaths
where population >= '0'  
	and  continent not like '' 
group by location, population
--order by 'Highest_Death_Count' desc


-- Creating view for InfectionRatePerCountry

Create view InfectionRatePerCountry as
select	location, 
		population, 
		Max(total_cases) as Highest_Infection_Count, 
		round(
			max(
				cast(total_cases as float)/cast(population as float)
				)
			 ,4)*100 
			 as 'Max_Infection_Rate(%)'
from CovidDeaths
where population >= '0'  and  continent not like '' 
group by location, population
--order by 'Max_Infection_Rate(%)' desc


-- Creating view for TotalCasesVsTotalDeaths

Create view TotalCasesVsTotalDeaths as
select location, date, total_cases, total_deaths, round((cast(total_deaths as float)/cast(total_cases as float)),4)*100 as 'Death_Rate(%)'
from CovidDeaths
where total_cases >= '0'  and  continent not like '' 
--order by location, date asc


-- Creating view for TotalCasesVsPopulation

Create view TotalCasesVsPopulation as
select location, date, population, total_cases, round((cast(total_cases as float)/cast(population as float)),4)*100 as 'Infection_Rate(%)'
from CovidDeaths
where population >= '0'  and  continent not like ''
--order by location, date 








select top 10 *
from CovidDeaths

select top 10 *
from CovidVaccinations


select distinct continent 
from CovidDeaths
where continent is not null

select *
from CovidDeaths
where location like '%world%'
order by date 


/*
select	location, 
		population, 
		SUM(cast(total_deaths as int)) as Highest_Death_Count, 
		round(
	--		max(
				SUM(cast(total_deaths as int))/cast(population as float)
	--			)
			 ,4)*100 
			 as 'Max_Death_Rate(%)'
from CovidDeaths
where population >= '0'  and  continent is not null  and location like '%states%'--or  total_deaths is not null
group by location, population
order by 'Highest_Death_Count' desc

*/




/*** This is not running becos total_cases and population are not recorded as integers/floats
select	location, 
		population, 
		max(total_cases) as Highest_Infection_Count, 
		round(max(total_cases/population) ,4)*100  as 'Max_Infection_Rate(%)'
from CovidDeaths
where population >= '0'  -- and location like '%kingdom%'--or  total_deaths is not null
group by location, population
order by 'Max_Infection_Rate(%)' desc
***/



select  *
from CovidVaccinations




