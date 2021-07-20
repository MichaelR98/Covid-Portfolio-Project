SELECT *
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4

--SELECT *
--FROM PortfolioProject..CovidVaccinations
--ORDER BY 3,4

-- Select Data that we will be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent is NOT NULL
ORDER BY 1,2 -- This order by statement orders the data by the 1st col given then the 2nd. 

-- Looking at Total Cases vs Total Deaths in the US and shows the likelihood of dying from COVID in the US

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS Death_Percentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%'
AND continent is NOT NULL
ORDER BY 1,2

--Looking at Total Case vs Population
--Shows % of population that has gotten Covid

SELECT location, date, total_cases, population, (total_cases/population)*100 AS Pop_with_Covid
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%'
AND continent is NOT NULL
ORDER BY 1,2

-- Looking at countries with highest infection rate compared to population

SELECT location, MAX(total_cases) AS Peak_Infection_Count, population, MAX((total_cases/population))*100 AS percent_pop_with_covid
FROM PortfolioProject..CovidDeaths
WHERE continent is NOT NULL
GROUP by location, population
ORDER BY percent_pop_with_covid desc

-- Showing counties with highest death count compared to population

SELECT location, MAX(CAST(total_deaths AS int)) AS Total_Death_Count, MAX((total_deaths/population))*100 AS death_percenatge -- CAST needed to change varchar to integer for MAX function
FROM PortfolioProject..CovidDeaths
WHERE continent is NOT NULL
GROUP by location
ORDER BY Total_Death_Count desc

--Breaking the data down by continent
-- Showing continents with highest death count

SELECT continent, MAX(CAST(total_deaths AS int)) AS Total_Death_Count , MAX((total_deaths/population))*100 AS death_percenatge -- CAST needed to change varchar to integer for MAX function
FROM PortfolioProject..CovidDeaths
WHERE continent is NOT NULL
GROUP by continent
ORDER BY Total_Death_Count desc

-- GLOBAL NUMBERS

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS int)) AS total_deaths, SUM(CAST(new_deaths AS int))/SUM(New_Cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null 
ORDER BY 1,2


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations -- colnames must be specified as being from a table
, SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.Location 
ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100, this does not work so a temp table in needed or a cte
From PortfolioProject..CovidDeaths dea -- giving the tables an alias 
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3

-- USE CTE

WITH PopVsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations -- colnames must be specified as being from a table
, SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.Location 
ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100, this does not work so a temp table in needed or a cte
FROM PortfolioProject..CovidDeaths dea -- giving the tables an alias 
JOIN PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null 
)
SELECT *,(RollingPeopleVaccinated/Population)*100
FROM PopVsVac

--TEMP TABLE

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null 