
SELECT *
FROM [Portfolio Project]..CovidDeaths
ORDER BY 3,4


SELECT *
FROM [Portfolio Project]..CovidVaccinations
ORDER BY 3,4

--Select Data we are using.

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM [Portfolio Project]..CovidDeaths
ORDER BY 1,2

-- Looking at total cases vs total deaths.

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercent
FROM [Portfolio Project]..CovidDeaths
WHERE total_deaths IS NOT NULL
ORDER BY 1,2

-- Death Percent for just US in 2022
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercent
FROM [Portfolio Project]..CovidDeaths
WHERE total_deaths IS NOT NULL AND location LIKE '%states%' AND date LIKE '%2022%'
ORDER BY 1,2

-- Totat cases vs population, as of today (~22.82% of the US population had a reported case of COVID-19)
SELECT Location, date, total_cases, population, (total_cases/population)*100 as CasePercentUS
FROM [Portfolio Project]..CovidDeaths
WHERE total_deaths IS NOT NULL AND location LIKE '%states%' 
ORDER BY 2 DESC

-- Highest infection rates of the countries with pop over 200,000,000
SELECT Location, MAX(total_cases), population, MAX((total_cases/population)*100) as CasePercent
FROM [Portfolio Project]..CovidDeaths
WHERE population > 200000000
GROUP BY Location, population
ORDER BY 4 DESC

-- Highest Death Count to Population, total_deaths has to be CAST as bigint, removing Continent totals
SELECT Location, MAX(cast(total_deaths as bigint))as TotalDeaths, population, MAX((total_deaths/population)*100) as TotalDeathsPercent
FROM [Portfolio Project]..CovidDeaths
WHERE total_deaths IS NOT NULL AND continent IS NOT NULL
GROUP BY Location, population
ORDER BY 4 DESC

-- Showing total deaths in each country
SELECT Location, MAX(cast(total_deaths as bigint))as TotalDeathsCountry, population
FROM [Portfolio Project]..CovidDeaths
WHERE total_deaths IS NOT NULL AND continent IS NOT NULL
GROUP BY Location, population
ORDER BY 2 DESC

-- Total deaths by continent
SELECT location, MAX(cast(total_deaths as bigint))as TotalDeaths, population
FROM [Portfolio Project]..CovidDeaths
WHERE total_deaths IS NOT NULL AND population IS NOT NULL AND continent IS NULL AND location NOT LIKE '%income%'
GROUP BY location, population
ORDER BY 2 DESC

-- Death Percentage by reported income
SELECT Location, MAX(cast(total_deaths as bigint))as TotalDeaths, population, MAX((total_deaths/population)*100) as TotalDeathsPercent
FROM [Portfolio Project]..CovidDeaths
WHERE total_deaths IS NOT NULL AND population IS NOT NULL AND continent IS NULL AND location LIKE '%income%'
GROUP BY Location, population
ORDER BY 4 DESC

-- Global Case Percentage Reported
SELECT location, MAX(cast(total_cases as bigint))as TotalCases, population, MAX(total_cases/population)*100 as TotalCasesPercent
FROM [Portfolio Project]..CovidDeaths
WHERE total_deaths IS NOT NULL AND population IS NOT NULL AND continent IS NULL AND location LIKE '%World%'
GROUP BY location, population
ORDER BY 2 DESC

-- Global death percentage Reported
SELECT location, MAX(cast(total_deaths as bigint))as TotalDeaths, population, MAX(total_deaths/population)*100 as TotalDeathPercent
FROM [Portfolio Project]..CovidDeaths
WHERE total_deaths IS NOT NULL AND population IS NOT NULL AND continent IS NULL AND location LIKE '%World%'
GROUP BY location, population
ORDER BY 2 DESC

-- Global Case Rate over time
SELECT date, location, MAX(cast(total_cases as bigint))as TotalCases, population, MAX(total_cases/population)*100 as TotalCasesPercent
FROM [Portfolio Project]..CovidDeaths
WHERE total_deaths IS NOT NULL AND population IS NOT NULL AND continent IS NULL AND location LIKE '%World%'
GROUP BY date, location, population
ORDER BY 2 DESC

-- Global Death Rate over time
SELECT date, location, MAX(cast(total_deaths as bigint))as TotalDeaths, population, MAX(total_deaths/population)*100 as TotalDeathPecent
FROM [Portfolio Project]..CovidDeaths
WHERE total_deaths IS NOT NULL AND population IS NOT NULL AND continent IS NULL AND location LIKE '%World%'
GROUP BY date, location, population
ORDER BY 2 DESC

-- Joining Deaths table with Vaccinations table
SELECT*
FROM [Portfolio Project]..CovidDeaths dea
JOIN [Portfolio Project]..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date

-- Total pop vs vaccination, partition to separate by country
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order BY dea.location, dea.date) as VaxDosesGivenToDate
FROM [Portfolio Project]..CovidDeaths dea
JOIN [Portfolio Project]..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND vac.new_vaccinations IS NOT NULL
ORDER BY 1,2,3

-- Using CTE
With PopvsVac(Continent, location, date, population, new_vaccinations, VaxDosesGivenToDate)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order BY dea.location, dea.date) as VaxDosesGivenToDate
FROM [Portfolio Project]..CovidDeaths dea
JOIN [Portfolio Project]..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND vac.new_vaccinations IS NOT NULL
)
Select *
FROM PopvsVac

-- TEMP Table

DROP TABLE IF EXISTS #VaxDosesGivenToDate
CREATE TABLE #VaxDosesGivenToDate
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
new_vaccination numeric,
VaxDosesGivenToDate numeric
)
INSERT INTO #VaxDosesGivenToDate
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order BY dea.location, dea.date) as VaxDosesGivenToDate
FROM [Portfolio Project]..CovidDeaths dea
JOIN [Portfolio Project]..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND vac.new_vaccinations IS NOT NULL
Select *
FROM #VaxDosesGivenToDate


-- Views for visualizations
CREATE VIEW VaxDosesGivenToDate AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order BY dea.location, dea.date) as VaxDosesGivenToDate
FROM [Portfolio Project]..CovidDeaths dea
JOIN [Portfolio Project]..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND vac.new_vaccinations IS NOT NULL

CREATE VIEW VaxDosesGivenUS AS
SELECT dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order BY dea.location, dea.date) as VaxDosesGivenUS
FROM [Portfolio Project]..CovidDeaths dea
JOIN [Portfolio Project]..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND vac.new_vaccinations IS NOT NULL AND dea.location LIKE '%state%'

Select *
FROM VaxDosesGivenUS

