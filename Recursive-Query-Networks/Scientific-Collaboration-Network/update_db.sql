DELETE FROM authordetails;
DELETE FROM paperdetails;
DELETE FROM authorpaperlist;
DELETE FROM citationlist;

\copy authordetails from 'Data/authordetails.csv' csv header;
\copy paperdetails from 'Data/paperdetails.csv' csv header;
\copy authorpaperlist from 'Data/authorpaperlist.csv' csv header;
\copy citationlist from 'Data/citationlist.csv' csv header;
