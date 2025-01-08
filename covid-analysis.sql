CREATE TABLE CovidDeaths (
[iso_code] VARCHAR(255),
[continent] VARCHAR(255),
[location] VARCHAR(255),
[date] DATETIME,
[population] FLOAT,
[total_cases] FLOAT,
[new_cases] FLOAT,
[new_cases_smoothed] FLOAT,
[total_deaths] FLOAT,
[new_deaths] FLOAT,
[new_deaths_smoothed] FLOAT,
[total_cases_per_million] FLOAT,
[new_cases_per_million] FLOAT,
[new_cases_smoothed_per_million] FLOAT,
[total_deaths_per_million] FLOAT,
[new_deaths_per_million] FLOAT,
[new_deaths_smoothed_per_million] FLOAT,
[reproduction_rate] FLOAT,
[icu_patients] FLOAT,
[icu_patients_per_million] FLOAT,
[hosp_patients] FLOAT,
[hosp_patients_per_million] FLOAT,
[weekly_icu_admissions] FLOAT,
[weekly_icu_admissions_per_million] FLOAT,
[weekly_hosp_admissions] FLOAT,
[weekly_hosp_admissions_per_million] FLOAT
);

BULK INSERT CovidDeaths
FROM 'C:/Users/hugoc/OneDrive/Documents/Portfolio/SQL Data Exploration/CovidDeaths.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2 -- Skip the header row
);

CREATE TABLE CovidVaccinations (
[iso_code] VARCHAR(255),
[continent] VARCHAR(255),
[location] VARCHAR(255),
[date] DATETIME,
[new_tests] FLOAT,
[total_tests] FLOAT,
[total_tests_per_thousand] FLOAT,
[new_tests_per_thousand] FLOAT,
[new_tests_smoothed] FLOAT,
[new_tests_smoothed_per_thousand] FLOAT,
[positive_rate] FLOAT,
[tests_per_case] FLOAT,
[tests_units] VARCHAR(255),
[total_vaccinations] FLOAT,
[people_vaccinated] FLOAT,
[people_fully_vaccinated] FLOAT,
[new_vaccinations] FLOAT,
[new_vaccinations_smoothed] FLOAT,
[total_vaccinations_per_hundred] FLOAT,
[people_vaccinated_per_hundred] FLOAT,
[people_fully_vaccinated_per_hundred] FLOAT,
[new_vaccinations_smoothed_per_million] FLOAT,
[stringency_index] FLOAT,
[population_density] FLOAT,
[median_age] FLOAT,
[aged_65_older] FLOAT,
[aged_70_older] FLOAT,
[gdp_per_capita] FLOAT,
[extreme_poverty] FLOAT,
[cardiovasc_death_rate] FLOAT,
[diabetes_prevalence] FLOAT,
[female_smokers] FLOAT,
[male_smokers] FLOAT,
[handwashing_facilities] FLOAT,
[hospital_beds_per_thousand] FLOAT,
[life_expectancy] FLOAT,
[human_development_index] FLOAT
);

BULK INSERT CovidVaccinations
FROM 'C:/Users/hugoc/OneDrive/Documents/Portfolio/SQL Data Exploration/CovidVaccinations.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2 -- Skip the header row
);

SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 3, 4

--SELECT *
--FROM PortfolioProject..CovidVaccinations
--ORDER BY 3, 4

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent is not null
ORDER BY 1, 2

-- Total Cases vs Total Deaths
-- Likelihood of fatality in specific country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE location like '%states%' and continent is not null
ORDER BY 1, 2

-- Total Cases vs Population
-- Percentage of Population contracted Covid
SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
FROM CovidDeaths
WHERE continent is not null
ORDER BY 1, 2

-- Countries with Highest Infection Rate compared to Population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM CovidDeaths
WHERE continent is not null
GROUP BY location, population
ORDER BY PercentPopulationInfected desc


-- Countries with Highest Death Count per Population
SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM CovidDeaths
-- WHERE location like '%states%'
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount desc


-- BY CONTINENT

SELECT continent, MAX(total_deaths) AS TotalDeathCount
FROM CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount desc


-- Continents with Highest Death Count per Population
SELECT continent, MAX(total_deaths) AS TotalDeathCount
FROM CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount desc



-- GLOBAL NUMBERS

SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1, 2


-- Total Population vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinations
, (RollingVaccinations/population)*100
FROM PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2, 3


-- USE CTE

WITH PopvsVac (Continent, Location, Date, Population, new_vaccinations, RollingVaccinations) 
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinations
-- , (RollingVaccinations/population)*100
FROM PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
-- ORDER BY 2, 3
)
SELECT *, (RollingVaccinations/Population)*100
FROM PopvsVac


-- TEMP TABLE

DROP TABLE IF exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingVaccinations numeric
)


INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinations
-- , (RollingVaccinations/population)*100
FROM PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
-- WHERE dea.continent is not null
-- ORDER BY 2, 3

SELECT *, (RollingVaccinations/Population)*100
FROM #PercentPopulationVaccinated

-- Create view to store data for visualizations
CREATE VIEW PercentPopulationVaccinated AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinations
-- , (RollingVaccinations/population)*100
FROM PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
 WHERE dea.continent is not null
 -- ORDER BY 2, 3


SELECT *
FROM PercentPopulationVaccinated