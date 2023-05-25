SELECT *
FROM [Covid Portfolio Project] ..covid_deaths
WHERE continent is not null
order by 3,4


--SELECT *
--FROM [Covid Portfolio Project] ..covid_vax
--order by 3,4

-- SELECT THE DATA THAT WE ARE GOING TO BE USING

SELEct Location, date, total_cases, new_cases, total_deaths, population
FROM [Covid Portfolio Project]..covid_deaths
WHERE continent is not null
ORDER BY 1,2

-- looking at the total cases vs total deaths

SELECT Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as Death_Percantage
FROM [Covid Portfolio Project]..covid_deaths
WHERE continent is not null
ORDER BY 1,2

-- Got an error that "Operand data type nvarchar is invalid for divide operator."

SELECT Location, date, total_cases, total_deaths, (CONVERT(DECIMAL, total_deaths) / CONVERT(DECIMAL, total_cases)) * 100 AS Death_Percentage
FROM [Covid Portfolio Project]..covid_deaths
WHERE continent is not null
ORDER BY 1, 2

SELECT Location, date, total_cases, total_deaths, (CONVERT(DECIMAL, total_deaths) / CONVERT(DECIMAL, total_cases)) * 100 AS Death_Percentage
FROM [Covid Portfolio Project]..covid_deaths
WHERE location like '%states%'
ORDER BY 1, 2

--Getting a look at the united states counts
-- Shows likelyhood if you contracy covid in your country


--looking at the total casses vs population
-- shows what percantage of the population got covid

SELECT Location, date, total_cases, population, (CONVERT(DECIMAL, total_cases) / CONVERT(DECIMAL, population)) * 100 AS Percent_Population_Infected
FROM [Covid Portfolio Project]..covid_deaths
WHERE location like '%states%'
ORDER BY 1, 2


-- looking at countries with highest infection rate compared to population


SELECT Location, population, MAX(total_cases) AS Highest_Infection_Count, population, MAX((CONVERT(DECIMAL, total_cases) / CONVERT(DECIMAL, population)) * 100) AS Percent_Population_Infected
FROM [Covid Portfolio Project]..covid_deaths
WHERE continent is not null
--WHERE location like '%states%'
Group BY location, population
ORDER BY Percent_Population_Infected DESC

--Showing the countries with the highest death count per population

SELECT Location, MAX(cast(total_deaths AS INT)) AS Total_Death_Count
FROM [Covid Portfolio Project]..covid_deaths
WHERE continent is not null
--WHERE location like '%states%'
Group BY location
ORDER BY Total_Death_Count DESC

-- breaking things down by comtinent
--showing continents with the highest death count

SELECT continent, MAX(cast(total_deaths AS INT)) AS Total_Death_Count
FROM [Covid Portfolio Project]..covid_deaths
WHERE continent is not null
--WHERE location like '%states%'
Group BY continent
ORDER BY Total_Death_Count DESC


--gobal numbers by date
-- got error Divide by zero error encountered. Warning: Null value is eliminated by an aggregate or other SET operation.
-- got a second error  Operand data type nvarchar is invalid for divide operator.
-- got a third error Error Divide by zero error encountered. Warning: Null value is eliminated by an aggregate or other SET operation.

SELECT date,
       SUM(new_cases) as total_cases,
       SUM(CAST(new_deaths as int)) as total_deaths,
       CASE WHEN SUM(new_cases) = 0 THEN NULL
            ELSE SUM(CAST(new_deaths as int)) * 100.0 / NULLIF(SUM(new_cases), 0)
       END as Death_Percentage
FROM [Covid Portfolio Project]..covid_deaths
WHERE continent is not null
GROUP BY date
ORDER BY date, total_cases;


--global numbers

SELECT SUM(new_cases) as total_cases,
       SUM(CAST(new_deaths as int)) as total_deaths,
       CASE WHEN SUM(new_cases) = 0 THEN NULL
            ELSE SUM(CAST(new_deaths as int)) * 100.0 / NULLIF(SUM(new_cases), 0)
       END as Death_Percentage
FROM [Covid Portfolio Project]..covid_deaths
WHERE continent is not null
--GROUP BY date
ORDER BY total_cases;


--looking at total population vs caccinations
-- ran into error Arithmetic overflow error converting expression to data type int. Warning: Null value is eliminated by an aggregate or other SET operation.
-- swapped int to bigint
SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations,
       SUM(CONVERT(bigint, vax.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as total_rolling_vaccinations
	   --(total_rolling_vaccinations/population)*100
FROM [Covid Portfolio Project]..covid_deaths dea
JOIN [Covid Portfolio Project]..covid_vax vax
	ON dea.location = vax.location
	AND dea.date = vax.date
WHERE dea.continent is not null
ORDER BY dea.location, dea.date


-- using a CTE
With pop_vs_vax (continent, location, date, population, new_vaccinations, total_rolling_vaccinations)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations,
       SUM(CONVERT(bigint, vax.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as total_rolling_vaccinations
	   --(total_rolling_vaccinations/population)*100
FROM [Covid Portfolio Project]..covid_deaths dea
JOIN [Covid Portfolio Project]..covid_vax vax
	ON dea.location = vax.location
	AND dea.date = vax.date
WHERE dea.continent is not null
--ORDER BY dea.location, dea.date
)
SELECT *, (total_rolling_vaccinations/population)*100
FROM pop_vs_vax


-- using a temp table

create table #percent_population_vaxed
(
continent nvarchar(255),
locatiob nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
total_rolling_vaccinations numeric,
)
insert into #percent_population_vaxed
SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations,
       SUM(CONVERT(bigint, vax.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as total_rolling_vaccinations
	   --(total_rolling_vaccinations/population)*100
FROM [Covid Portfolio Project]..covid_deaths dea
JOIN [Covid Portfolio Project]..covid_vax vax
	ON dea.location = vax.location
	AND dea.date = vax.date
WHERE dea.continent is not null
--ORDER BY dea.location, dea.date

SELECT *, (total_rolling_vaccinations/population)*100
FROM #percent_population_vaxed


--creating view to store data for later viz

create view percent_population_vaxed as
SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations,
       SUM(CONVERT(bigint, vax.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as total_rolling_vaccinations
	   --(total_rolling_vaccinations/population)*100
FROM [Covid Portfolio Project]..covid_deaths dea
JOIN [Covid Portfolio Project]..covid_vax vax
	ON dea.location = vax.location
	AND dea.date = vax.date
WHERE dea.continent is not null
--order by 2,3

SELECT *
FROM percent_population_vaxed