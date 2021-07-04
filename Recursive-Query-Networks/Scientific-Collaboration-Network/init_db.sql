create table authordetails (
  authorid bigint,
  authorname text,
  city text,
  gender text,
  age bigint,
  constraint authordetails_key primary key (authorid)
);

create table paperdetails (
  paperid bigint,
  papername text,
  conferencename text,
  score bigint,
  constraint paperdetails_key primary key (paperid)
);

create table authorpaperlist (
  authorid bigint,
  paperid bigint,
  constraint authorpaperlist_key primary key (authorid,paperid)
);

create table citationlist (
  paperid1 bigint,
  paperid2 bigint,
  constraint citationlist_key primary key (paperid1,paperid2)
);

\copy authordetails from 'Data/authordetails.csv' csv header;
\copy paperdetails from 'Data/paperdetails.csv' csv header;
\copy authorpaperlist from 'Data/authorpaperlist.csv' csv header;
\copy citationlist from 'Data/citationlist.csv' csv header;
