/*
Exploration des données Covid-19

Compétences utilisées : Jointures, CTE (Common Table Expressions), Tables temporaires, Fonctions fenêtres, Fonctions d’agrégat, Création de vues, Conversion de types de données

*/

SELECT * 
FROM portfolioproject.coviddeaths
WHERE continent IS NOT NULL;

-- Sélectionner les données avec lesquelles nous allons commencer
SELECT 
    Location, 
    date, 
    total_cases, 
    new_cases, 
    total_deaths, 
    population
FROM portfolioproject.coviddeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;

-- Total des cas vs Total des décès
-- Montre la probabilité de mourir si vous contractez la Covid dans votre pays

SELECT Location, 
       date, 
       total_cases,
       total_deaths, 
       (total_deaths/total_cases)*100 AS DeathPercentage
FROM portfolioproject.coviddeaths
WHERE location LIKE '%Afghanistan%'
  AND continent IS NOT NULL 
ORDER BY 1,2;

-- Total des cas vs Population
-- Montre quel pourcentage de la population est infecté par la Covid

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From portfolioproject.coviddeaths
Where location like '%Afghanistan%'
order by 1,2


-- Pays ayant le taux d’infection le plus élevé par rapport à la population

-- Pays ayant le taux d’infection le plus élevé par rapport à la population
SELECT 
    Location,
    MAX(Population) AS Population,
    MAX(total_cases) AS HighestInfectionCount,
    MAX(total_cases / Population) * 100 AS PercentPopulationInfected
FROM portfolioproject.coviddeaths
GROUP BY Location
ORDER BY PercentPopulationInfected DESC;

-- Pays ayant le plus grand nombre de décès par rapport à la population

SELECT 
    Location, 
    MAX(CAST(Total_deaths AS SIGNED)) AS TotalDeathCount
FROM portfolioproject.coviddeaths
GROUP BY Location
ORDER BY TotalDeathCount DESC
LIMIT 20;


-- DÉCOUPER LES DONNÉES PAR CONTINENT

-- Montrer les continents avec le plus grand nombre de décès par rapport à la population

SELECT continent, 
       MAX(CAST(Total_deaths AS SIGNED)) AS TotalDeathCount
FROM portfolioproject.coviddeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;


-- CHIFFRES MONDIAUX
SELECT 
    SUM(new_cases) AS total_cases, 
    SUM(CAST(new_deaths AS SIGNED)) AS total_deaths, 
    SUM(CAST(new_deaths AS SIGNED)) / NULLIF(SUM(new_cases),0) * 100 AS DeathPercentage
FROM portfolioproject.coviddeaths
WHERE continent IS NOT NULL;



-- Population totale vs Vaccinations
-- Montre le pourcentage de la population ayant reçu au moins une dose de vaccin contre la Covid

SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS SIGNED)) 
        OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
-- , (RollingPeopleVaccinated / population) * 100 AS PercentVaccinated
FROM portfolioproject.coviddeaths dea
JOIN portfolioproject.covidvaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date;


-- Utilisation d’un CTE pour effectuer le calcul avec PARTITION BY dans la requête précédente

WITH PopvsVac AS (
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations,
        SUM(CAST(vac.new_vaccinations AS SIGNED)) 
            OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
    FROM portfolioproject.coviddeaths dea
    JOIN portfolioproject.covidvaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT *, 
       (RollingPeopleVaccinated / CAST(Population AS SIGNED)) * 100 AS PercentVaccinated
FROM PopvsVac
ORDER BY location, date;




-- Utilisation d’une table temporaire pour effectuer le calcul avec PARTITION BY dans la requête précédente
DROP TEMPORARY TABLE IF EXISTS PercentPopulationVaccinated;

CREATE TEMPORARY TABLE PercentPopulationVaccinated (
    Continent VARCHAR(255),
    Location VARCHAR(255),
    Date DATETIME,
    Population BIGINT,
    New_vaccinations BIGINT,
    RollingPeopleVaccinated BIGINT
);

INSERT INTO PercentPopulationVaccinated
SELECT 
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS SIGNED)) 
        OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM portfolioproject.coviddeaths dea
JOIN portfolioproject.covidvaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date;

SELECT *,
       (RollingPeopleVaccinated / CAST(Population AS SIGNED)) * 100 AS PercentVaccinated
FROM PercentPopulationVaccinated
ORDER BY Location, Date;




-- Création d’une vue pour stocker les données en vue de visualisations ultérieures

CREATE OR REPLACE VIEW PercentPopulationVaccinated AS
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS SIGNED)) 
        OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
-- , (RollingPeopleVaccinated / CAST(population AS SIGNED)) * 100 AS PercentVaccinated
FROM portfolioproject.coviddeaths dea
JOIN portfolioproject.covidvaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;









