--Check tables are there correctly

SELECT *
FROM PortfolioProject1A..CovidDeaths
Where continent is not null
order by 3,4

SELECT *
FROM PortfolioProject1A..CovidVaccinations
Where continent is not null
order by 3,4


--Select Data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject1A..CovidDeaths
Where continent is not null
order by 1,2


-- Comparing Total Cases vs Total Deaths (Percentage of deaths / total cases)
-- Look for percentage of deaths in my country (Spain)

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject1A..CovidDeaths
where location like 'Spain'
order by 1,2


-- Comparing Total Cases vs Population in my country
-- Shows what percentage of the population got COVID

SELECT location, date, total_cases, population, (total_cases/population)*100 as CasesPercentage
FROM PortfolioProject1A..CovidDeaths
where location like 'Spain'
order by 1,2

-- Find out which Countries have highest infection rates / population

SELECT location, population, MAX(total_cases) AS HighestInfCount, MAX((total_cases/population))*100 as PercPopulationInfected
FROM PortfolioProject1A..CovidDeaths
Where continent is not null
GROUP BY location, population
order by 4 desc

-- Find out which Countries have highest Death count 

SELECT location, MAX(cast (total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject1A..CovidDeaths
Where continent is not null
GROUP BY location
ORDER BY 2 desc

-- Finding out Max Death Count by Continent

SELECT continent, MAX(cast (total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject1A..CovidDeaths
Where continent is not null
GROUP BY continent
ORDER BY 2 desc

-- Another way of checking MAX Death Count by locations that are not countries (includes continent but also int)

SELECT location, MAX(cast (total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject1A..CovidDeaths
Where continent is null
GROUP BY location
ORDER BY 2 desc

--Showing continents with highest death count per population

SELECT location, MAX(cast (total_deaths as int)) AS TotalDeathCount, MAX((total_deaths/population))*100 as PercDeathsPopulation
FROM PortfolioProject1A..CovidDeaths
Where continent is null
GROUP BY location
ORDER BY 2 desc

SELECT continent, MAX(cast (total_deaths as int)) AS TotalDeathCount, MAX((total_deaths/population))*100 as PercDeathsPopulation
FROM PortfolioProject1A..CovidDeaths
Where continent is not null
GROUP BY continent
ORDER BY 2 desc

-- Global numbers

SELECT date, SUM(new_cases) as Cases, SUM(cast(new_deaths as int)) AS Deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM PortfolioProject1A..CovidDeaths
Where continent is not null
GROUP by date
order by 1,2

SELECT SUM(new_cases) as Cases, SUM(cast(new_deaths as int)) AS Deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM PortfolioProject1A..CovidDeaths
Where continent is not null
order by 1,2

--Total Population vs Total Vaccinations - How many people in the world were vaccinated?

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) as TotalVaccinations
FROM PortfolioProject1A..CovidDeaths dea
JOIN PortfolioProject1A..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
Where dea.continent is not null and vac.continent is not null
Order by 2,3

-- Calculate percentage of people vaccinated in regards to population
-- Can't use SUM of new vaccinations, a column we just created, to operate with it 

-- Solution 1 - Store the info from that column in a CTE

WITH PopVSVac (continent, location, date, population, new_vaccinations, TotalVaccinations)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) as TotalVaccinations
FROM PortfolioProject1A..CovidDeaths dea
JOIN PortfolioProject1A..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
Where dea.continent is not null and vac.continent is not null
) 
Select *, (TotalVaccinations/population)*100 as VaccPercentage
From PopVSVac

-- Solution 2 - Use a Temp Table

Drop Table if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
Total_Vaccinations numeric
)

Insert into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) as TotalVaccinations
FROM PortfolioProject1A..CovidDeaths dea
JOIN PortfolioProject1A..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
Where dea.continent is not null and vac.continent is not null


Select *, (Total_Vaccinations/population)*100 as VaccPercentage
From #PercentPopulationVaccinated

--Creating Views to store data for later visualization

--View for Percentage of Vaccinations 

CREATE VIEW PercentPopulationVaccinated as

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, 
dea.date) as TotalVaccinations
FROM PortfolioProject1A..CovidDeaths dea
JOIN PortfolioProject1A..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
Where dea.continent is not null and vac.continent is not null


Select * 
From PercentPopulationVaccinated 

--View for death rates by continent

CREATE VIEW DeathRateCont as

SELECT continent, MAX(cast (total_deaths as int)) AS TotalDeathCount, MAX((total_deaths/population))*100 as PercDeathsPopulation
FROM PortfolioProject1A..CovidDeaths
Where continent is not null
GROUP BY continent

Select *
From DeathRateCont
Order by 3 DESC

--View for Max death count by continent

CREATE VIEW MaxDeathCont as

SELECT continent, MAX(cast (total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject1A..CovidDeaths
Where continent is not null
GROUP BY continent

Select *
FROM MaxDeathCont
Order by 2 DESC

-- View for infection rates / population by country

CREATE VIEW InfectRatesLoc as

SELECT location, population, MAX(total_cases) AS HighestInfCount, MAX((total_cases/population))*100 as PercPopulationInfected
FROM PortfolioProject1A..CovidDeaths
Where continent is not null
GROUP BY location, population

Select *
FROM InfectRatesLoc
Order by 4 desc

-- View for Max Death count by country

CREATE VIEW MaxDeathLoc as

SELECT location, MAX(cast (total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject1A..CovidDeaths
Where continent is not null
GROUP BY location

Select *
FROM MaxDeathLoc
Order by 2 DESC