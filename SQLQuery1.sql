SELECT *
FROM PortfolioProject..CovidDeathsProject$
ORDER BY 3,4


--SELECT *
--FROM PortfolioProject..CovidVaccinationsProject$
--ORDER BY 3,4

--Select Data we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeathsProject$
ORDER BY 1,2

--Looking at total cases vs total deaths
--Shows death rate of covid if you were to contract the virus in the United States

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS 'death pct'
FROM PortfolioProject..CovidDeathsProject$
WHERE location LIKE '%States%' 
ORDER BY 1,2

--Looking at deadliest day of the year in the United States for 2021
--Deadliest day of the year was 12-31

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS 'death pct'
FROM PortfolioProject..CovidDeathsProject$
WHERE location LIKE '%States%' 
AND date LIKE '%2021%'
ORDER BY 4 DESC

--Looking at total cases vs population in the United States
--Shows us percentage of population that is infected

SELECT location, date, total_cases, population, (total_cases/population)*100 AS 'infection pct'
FROM PortfolioProject..CovidDeathsProject$
WHERE location LIKE '%States%' 
ORDER BY 1,2

--Looking at Countries with Highst Infection Rate compared to Population
--We find that countries with smaller populations have the highest rate of infection, this is especially true in island countries.
SELECT location, population, MAX(total_cases) AS 'HighestInfectionCount', MAX((total_cases/population))*100 AS 'infection pct'
FROM PortfolioProject..CovidDeathsProject$
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 4 DESC

--Looking at highest rate of infection in larger countries (population > 100,000,000)
--We find that developed countries have the highest infection percentage. This could be due to increased reporting and higher vailability to testing.
SELECT location, population, MAX(total_cases) AS 'HighestInfectionCount', MAX((total_cases/population))*100 AS 'infection pct'
FROM PortfolioProject..CovidDeathsProject$
WHERE population > 100000000 AND continent IS NOT NULL
GROUP BY location, population
ORDER BY 4 DESC


--Showing countries with highest death count per population
--We see that the United States has the most deaths.
SELECT location, MAX(cast(total_deaths as int)) AS 'Total Deaths', MAX((total_deaths/population))*100 AS 'Death Percentage'
FROM PortfolioProject..CovidDeathsProject$
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 2 DESC

--BREAKING DATA DOWN BY CONTINENT
--Death count by continent and income level

SELECT location, MAX(cast(total_deaths as int)) AS 'Total Deaths'
FROM PortfolioProject..CovidDeathsProject$
WHERE continent IS NULL
GROUP BY location
ORDER BY 2 DESC

--GLOBAL NUMBERS

--This shows us the total cases, total deaths, and death percentage ordered by date

SELECT date, SUM(new_cases) AS 'Total Cases', SUM(CAST(new_deaths as int)) AS 'Total Deaths', SUM(CAST(new_deaths as int))/SUM(new_cases)*100 AS 'Death Percentage'
FROM PortfolioProject..CovidDeathsProject$
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1

--This shows us the deadliest day in terms of Total Deaths
--The deadliest day in this data set was 2021-01-20
SELECT date, SUM(new_cases) AS 'Total Cases', SUM(CAST(new_deaths as int)) AS 'Total Deaths', SUM(CAST(new_deaths as int))/SUM(new_cases)*100 AS 'Death Percentage'
FROM PortfolioProject..CovidDeathsProject$
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 3 DESC

--This shows us the total numbers for the whole pandemic
SELECT SUM(new_cases) AS 'Total Cases', SUM(CAST(new_deaths as int)) AS 'Total Deaths', SUM(CAST(new_deaths as int))/SUM(new_cases)*100 AS 'Death Percentage'
FROM PortfolioProject..CovidDeathsProject$
WHERE continent IS NOT NULL
ORDER BY 1

--VACCINATION NUMBERS
--This shows us total vaccinations numbers for the United States
SELECT location, date, people_fully_vaccinated, population
FROM PortfolioProject..CovidVaccinationsProject$
WHERE location LIKE 'United States'
ORDER BY 2

--Looking at the vaccination percentage of the  United States population

SELECT location, date, people_fully_vaccinated, population, (people_fully_vaccinated/population)*100 AS 'Vaccination Percentage'
FROM PortfolioProject..CovidVaccinationsProject$
WHERE location LIKE 'United States' 
AND total_vaccinations IS NOT NULL
ORDER BY 2


SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS 'RollingPeopleVaccinated',
--(RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeathsProject$ dea
JOIN PortfolioProject..CovidVaccinationsProject$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

--USE CTE
WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS 'RollingPeopleVaccinated'
--(RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeathsProject$ dea
JOIN PortfolioProject..CovidVaccinationsProject$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopvsVac


--TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinatedTable
CREATE TABLE #PercentPopulationVaccinatedTable
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)


INSERT INTO #PercentPopulationVaccinatedTable
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS 'RollingPeopleVaccinated'
--(RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeathsProject$ dea
JOIN PortfolioProject..CovidVaccinationsProject$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinatedTable

--Creating view for later data visualization

CREATE VIEW PercentPopulationVaccinatedTable AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS 'RollingPeopleVaccinated'
--(RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeathsProject$ dea
JOIN PortfolioProject..CovidVaccinationsProject$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

CREATE VIEW InfectionRateVSPopulation AS
SELECT location, population, MAX(total_cases) AS 'HighestInfectionCount', MAX((total_cases/population))*100 AS 'infection pct'
FROM PortfolioProject..CovidDeathsProject$
WHERE continent IS NOT NULL
GROUP BY location, population
--ORDER BY 4 DESC

CREATE VIEW InfectionRateInLargeCountries AS
SELECT location, population, MAX(total_cases) AS 'HighestInfectionCount', MAX((total_cases/population))*100 AS 'infection pct'
FROM PortfolioProject..CovidDeathsProject$
WHERE population > 100000000 AND continent IS NOT NULL
GROUP BY location, population
--ORDER BY 4 DESC

CREATE VIEW DeathCountByContinentAndIncomeLevel AS
SELECT location, MAX(cast(total_deaths as int)) AS 'Total Deaths'
FROM PortfolioProject..CovidDeathsProject$
WHERE continent IS NULL
GROUP BY location
--ORDER BY 2 DESC