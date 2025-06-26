-- Create Table for raw movies
CREATE TABLE staging_movies (
	id INT,
	original_title TEXT,
	original_language TEXT,
	genres JSON,
	budget BIGINT,
	revenue BIGINT,
	runtime FLOAT, 
	release_date TEXT,
	production_companies JSON,
	production_countries JSON,
	vote_average FLOAT
);

-- Add keywords column to the raw data table
ALTER TABLE staging_movies ADD keywords JSON;

-- Populate table with data from csv file
COPY staging_movies (id, original_title, original_language, 
genres, budget, revenue, runtime, release_date, production_companies,
production_countries, vote_average, keywords)
FROM 'C:\Users\vanda\Desktop\Jupyter Notebook\Project_Data\tmdb_5000_movies_raw.csv'
DELIMITER ',' 
CSV HEADER;

-- Check if data is in the table
SELECT * FROM staging_movies;

-- Data to extract from JSON columns
-- genres, production companies, production countries, keywords

-- Create a cleaned data table
CREATE TABLE movies_cleaned (
	id INT PRIMARY KEY, 
	original_title TEXT, 
	original_language TEXT,
	genres TEXT,
	budget BIGINT,
	revenue BIGINT,
	runtime FLOAT,
	release_date TEXT,
	production_companies_list TEXT,
	production_countries_list TEXT,
	vote_average FLOAT,
	keywords TEXT
);

-- Flattened data
CREATE TABLE movie_genres (
	movie_id INT,
	genre TEXT
);

CREATE TABLE movie_productions_countries (
	movie_id INT,
	country TEXT
);

CREATE TABLE movie_productions_companies (
	movie_id INT,
	company TEXT
);

INSERT INTO movie_genres (movie_id, genre)
SELECT id, c->> 'name' 
FROM staging_movies, json_array_elements(genres) AS c
WHERE genres IS NOT NULL;

INSERT INTO movie_productions_countries (movie_id, country)
SELECT id, c->> 'name'
FROM staging_movies, json_array_elements(production_countries) AS c
WHERE production_countries IS NOT NULL;

INSERT INTO movie_productions_companies (movie_id, company)
SELECT id, c->> 'name'
FROM staging_movies, json_array_elements(production_companies) AS c
WHERE production_companies IS NOT NULL;


-- Cleaned Data 
INSERT INTO movies_cleaned(
    id, original_title, original_language, 
    genres, budget, revenue, runtime, release_date, 
    production_companies_list, production_countries_list, vote_average, keywords
)
SELECT 
    m.id,
    m.original_title,
    m.original_language,
    (
        SELECT STRING_AGG(g->>'name', ', ')
        FROM json_array_elements(m.genres) AS g
    ) AS genres,
    m.budget,
    m.revenue,
    m.runtime,
    m.release_date,
    (
        SELECT STRING_AGG(p->>'name', ', ')
        FROM json_array_elements(m.production_companies) AS p
    ) AS production_companies_list,

    (
        SELECT STRING_AGG(c->>'name', ', ')
        FROM json_array_elements(m.production_countries) AS c
    ) AS production_countries_list,
    m.vote_average,
    (
        SELECT STRING_AGG(k->>'name', ', ')
        FROM json_array_elements(m.keywords) AS k
    ) AS keywords_list
FROM 
    staging_movies m
WHERE
    m.budget > 0 AND 
    m.revenue > 0 AND 
    json_typeof(m.genres) = 'array';
