Reproducible road safety research: an exploration of the shifting
spatial and temporal distribution of car-pedestrian crashes
================
Dr Robin Lovelace — University of Leeds, Consumer Data Research Centre
(CDRC) and Institute for Transport Studies (ITS) and Leeds Institute for
Data Analytics (LIDA)
2019-01-24

# Summary

This paper demonstrates a reproducible analysis workflow for
downloading, formatting and analysing road crash data. Building on the
recently published **stats19** R package, the paper contains code that
downloads 691,641 crash incidents, which are filtered-down to 78,448
car-pedestrian crashes. The dataset reveals variability in crash
characteristics depending on the age of the person hurt, speed limits
and location (urban-rural in the first instance). More importantly, the
beginnings of evaluation metrics are shown using high-level geographic
aggregation, raising many further questions and directions for future
research using open road crash
data.

<!-- Authors are requested to keep to the word limit of 1500 words. The word limit includes the main body of the abstract and everything within (including captions etc.,) and the references. Not included in the word count is the title, author list, date, summary, keywords and author biographies -->

**Keywords:** geographic analysis, road safety, reproducibility

# Introduction

This paper is motivated by two high-level policy and academic
objectives, which intersect. The policy objective is to make decisions
be made with reference to and understanding of high quality evidence
that is based on the ‘best available data’. The academic object is to
ensure that research findings can be reproduced, to ensure scientific
falsifiability and to encourage collaboration and cooperation between
researchers, rather than competition. These two objectives intersect
because without them it is difficult to generate high quality evidence,
that can be externally verified, without reproducible methods.
Conversely, an academic environment that is conducive to collaboration
and not competition requires a government that supports open science,
“the transparent and accessible knowledge \[and methods\] shared and
developed through collaborative networks” (Vicente-Saez and
Martinez-Fuentes 2018).

This context is relevant to many fields of research that have practical
and policy implications, and road safety research is no exceptions, as
its findings often have direct policy implications and can be highly
emotive, raising questions about the divide between research and policy
(Elvik et al. 2009):

> Can science and politics be kept apart in such a highly applied field
> of research? Where is the dividing line between science and politics
> in road safety?

More specifically, how can road safety research become more
reproducible? This would clearly have advantages for many stakeholders:
local and national governments would be better equipped to justify their
road safety policies if the evidence on which they are based is the
result of reproducible research conducive to ‘citizen science’ (Bonney
et al. 2014); advocacy groups such as RoadPeace would be able to engage
not only in lobbying, but also science, encouraging arguments from all
sides to be based more on objective evidence, rather than emotive
anecdote; and citizens themselves should benefit, from better road
safety policies and the educational opportunities created by open
science.

These considerations, and the more mundane observation that dozens of
researchers were duplicating effort by cleaning STATS19 data — the
official source of road crash data in Great Britain (Department for
Transport 2017) — instead of pooling resources to allow the focus to
shift onto the research, lead to the development of software written in
the statistical programming language R (R Core Team 2019): **stats19**,
an R package that was released on the Comprehensive R Archive Network
(CRAN) in January 2019 (R Lovelace et al. 2019).

Much road safety research has been done using Geographic Information
Systems (GIS) software (e.g. Kim and Levine 1996; Peled and Hakkert
1993; Steenberghen et al. 2004; Razzak, Khan, and Jalal 2011) and, with
the growth of open source GIS products such as QGIS, this is a trend
that can encourage open science, as defined above. A limitation of
dedicated GIS software products from a reproducibility perspective,
however, is that they tend to be based on a graphic user interface
(GUI), rather than a command-line interface (CLI). This has led to many
efforts to push geographic research in a more computational directions,
under labels such as Geographic Information Science (GIScience),
Geographic Data Science, and Geocomputation (Robin Lovelace, Nowosad,
and Meunchow 2019).

On a practical level, the approach demonstrated in this paper is
conducive reproducible research because it uses code to define the
geographic analysis steps undertaken. The use of RMarkdown to generate
this paper ensure reproducibility: all main analysis steps are shown in
code chunks which re-run each time the document is compiled (Xie,
Allaire, and Grolemund 2018). Beyond the high-level aims of
evidence-based policy and reproducible research outlined above, this
paper has a more specific purpose: to show that geographic road safety
research *can* be reproducible, with an example that presents new
findings on the shifting spatial distribution of car-pedestrian crashes
at the national level over the last 5 years.

# Set-up and data preparation

The R packages used in this paper can be installed and loaded as
follows:

``` r
pkgs = c(
  "tidyverse",
  "sf",
  "stats19",
  "tmap"
)
```

``` r
install.packages(pkgs)
purrr::map_lgl(pkgs, require, character.only = TRUE)
```

    ## tidyverse        sf   stats19      tmap 
    ##      TRUE      TRUE      TRUE      TRUE

The following code downloads, formats and combines crash data over the
past 5 years as follows:

``` r
y = 2013:2017
a = map_dfr(y, get_stats19, type = "accidents", ask = FALSE)
```

The resulting datasets is large, consisting of more than half a million
<!-- () --> (691,641) rows (crash points), with

31 columns (see R Lovelace et al. 2019 for details on the data). This is
easy to work with in-memory on modern computers, however, consuming 1/3
GB of RAM. These can be converted into a spatial class, defined by the
**sf** package (Pebesma 2018). A sample of 1000 is taken and plotted,
for demonstration purposes, as follows (see the resulting Figure 1):

``` r
a_sf = format_sf(a)
a_sample = a_sf %>% sample_n(1000)
```

``` r
plot(a_sample)
```

![Columns of ‘a\_sample’ variable plotted separately on a UK
map.](README_files/figure-gfm/uk-plot1-1.png)

Having gained a measure of the crash data, and some key descriptive
statistics, we can proceed to join-on the associated casualty and
vehicle tables. The following command uses the argument `type` to
specify which table from the STATS19 schema is to be read-in:

``` r
c = map_dfr(y, get_stats19, type = "casualties", ask = FALSE)
v = map_dfr(y, get_stats19, type = "vehicle", ask = FALSE)
```

We are interested in accidents in which a pedestrian was hurt, and where
the (only) vehicle involved was a car. This subset of the casualties
dataset can be extracted as follows:

``` r
c_ped = c %>% filter(casualty_type == "Pedestrian")
v_car = v %>% filter(vehicle_type == "Car")
a_cp = a_sf %>%
  filter(number_of_vehicles == 1 & number_of_casualties == 1) %>% 
  filter(accident_index %in% c_ped$accident_index) %>% 
  filter(accident_index %in% v_car$accident_index)
```

Before proceeding, it’s worth joining-on the vehicle and crash tables
onto the crash data:
<!-- , keeping only records in which casualty *and* vehicle data is present. -->

``` r
a_cpj = a_cp %>% 
  inner_join(v_car) %>% 
  inner_join(c_ped)
```

The resulting dataset, `a_cpj`, contains 78,454 rows: 11% of the crashes
in the original dataset represent a car-pedestrian collision involving a
single vehicle and a single casualty (the pedestrian). This is the
dataset, that also contains 68 columns, will be used for the remainder
of this analysis. The final code chunk this section generates a couple
of plots, to give us an idea of the nature of car-pedestrian crashes. As
illustrated in Figures 2 and 3, the results match prior expectations:
elderly people (in the 66-75 and 75+ age bands) and fast roads (40 to 70
miles per hour) tend to result in more serious and fatal injuries.

``` r
g = ggplot(a_cpj)
```

``` r
p1 = g + geom_bar(aes(accident_severity, fill = urban_or_rural_area)) +
 facet_wrap(vars(speed_limit), scales = "free_y") +
  labs(fill = "Location")
p2 = g + geom_bar(aes(accident_severity, fill = impact)) +
  facet_wrap(vars(age_band_of_casualty), scales = "free_y") +
  theme(axis.text.x = element_text(angle = 45))
```

![Crash severity by speed limit (top) and crash severity by age band of
casualty (bottom)](README_files/figure-gfm/unnamed-chunk-16-1.png)

# Geographic analysis and results

The data is still in a spatial form, of class `sf`, enabling geographic
analysis. Although the geographic resolution of the data is high, ~10 m,
we will analyse it at the national level, to investigate the relative
performance of different police forces over time. A geographic join will
be used to assign a police force to each crash (although police force is
already a variable in the dataset):

``` r
agg_slight = aggregate(a_cpj["accident_severity"], police_boundaries,
                      function(x) sum(grepl(pattern = "Slight", x)))
```

![Overview of crashes by police force area, showing relative numbers of
slight, serious and fatal
injuries.](README_files/figure-gfm/unnamed-chunk-19-1.png)

Repeating this process for each crash severity type results in the plot
presented in Figure 4. Because a relative scale is used between the
different crash categories, the results shown in Figure 4 shows that,
outside London, serious and fatal crashes are comparatively common in
some areas. We can identify which police forces have the highest
*ratios* of crashes that are reported as fatal. The top 5 and bottom 5
are shown in Table 1, which shows wide variability. As would be
expected, large cities (where average speeds tend to be low) tend to
have a relatively low percentage of car-pedestrian casualties that are
fatal, whereas predominantly rural forces such as Wiltshire and
Gloucestershire (where the roads tend to be faster, and there are fewer
crashes overall) tend to have a relatively high proportion that are
fatal. Devon and Cornwall is an outlier: a relatively rural force with a
low proportion of fatalities. Further research could seek to explore the
reasons for this variability.

| name                | slight | serious | fatal | percent\_fatal |
| :------------------ | -----: | ------: | ----: | -------------: |
| Wiltshire           |    428 |     155 |    15 |            2.5 |
| Gloucestershire     |    347 |     137 |    10 |            2.0 |
| West Mercia         |    772 |     216 |    20 |            2.0 |
| Northamptonshire    |    515 |     187 |    14 |            2.0 |
| Suffolk             |    546 |     116 |    13 |            1.9 |
| NA                  |     NA |      NA |    NA |             NA |
| Devon and Cornwall  |   1556 |     384 |    16 |            0.8 |
| Lancashire          |   1718 |     626 |    19 |            0.8 |
| Nottinghamshire     |   1102 |     290 |    10 |            0.7 |
| Metropolitan Police |  13552 |    2303 |   109 |            0.7 |
| City of London      |     69 |      21 |     0 |            0.0 |

Top and bottom 5 police forces in terms of the percentage of
car-pedestrian crashes that are fatal.

What about variability *over time*? The overall trend in the number of
pestrians hit by cars can be seen in Figure 4, which shows the total
number of people by month, broken-down by crash severity. This result
shows that pedestrian casualty rates have essentially flat-lined over
the past 5 years, after decades of improvement. What the data does not
show, however, is the geographic breakdown of these trends.

![Variability of crash rates over
time.](README_files/figure-gfm/unnamed-chunk-21-1.png)

A geographic join can assign each crash to a police authority as
follows:

``` r
a_cps = st_join(a_cpj, police_boundaries)
```

The new object has the variable `pfa16nm`, the police force name, which
can be subsequently aggregated and then joined back onto the geographic
variable of `police_boundaries`. Before we plot the ‘best’ and ‘worst’
performers geographically, let’s see the temporal trend of the top and
bottom forces in terms of the percentage of casualties that were fatal
(see Table 1). The results, presented in Figure 5, suggest that London
(controlled by the Metropolitan Police) has seen an increase in serious,
and to a lesser extent slight and fatal, pedestrian casualties since
around the beginning of 2016. Lancaster has seen an increas in the
number of fatalities per month, beginning around the same time. These
raise the question: why? Rather than answer this question, the final
analysis will explore the geographic distribution of improving/worsening
performance by crash type.

![Average number of pedestrian casualties by severity and police force
in a selection of areas (see Table
1)](README_files/figure-gfm/unnamed-chunk-23-1.png)

When the analysis presented in Figure 5 is conducted for *all* police
jurisdictions, and an aggregate measure of ‘direction of trend’ is used
(in this case, average increase/decrease in counts of crashes of
different severity levels per year) is used, we can see the spatial
distribution of improvement in casualty numbers across the country (see
Figure 6). It is clear that, assuming crash counts are a good metric of
safety (which may not always hold, but is sufficient for the purposes of
this paper), some areas perform much better than others. In terms of
fatal car-pedestrian crashes, it is clear that large regions including
West Yorkshire, Greater Manchester and Northumbria are not performing
well. The trend for serious car-pedestrian crashes is even more mixed,
with London and regions to the east (including Kent and Essex), seeing
substantial upward trends in the number of pedestrians sersiously hurt
in car crashes.

![Trend in car-pedestrian casualties by region, 2013 to 2017, in units
of average number of additional casualties per year, by severity of
injuries.](README_files/figure-gfm/unnamed-chunk-24-1.png)

# Discussion

This paper has provided a taster of what is possible with open road
crash data, automatically downloaded and formatted using the **stats19**
package. It reveals interesting regional differences in the numbers,
proportions and trends of one particular type of road crash:
car-pedestrian collisions. Although the roads are complex systems, and
further research should seek to identify suitable denominators of risk
(e.g. walking rates), we can draw some conclusions. The absolute and
proportional increase in serious casualties in London is concerning,
especially given the government’s commitment to contribute to the
European Union’s target of halving road traffic deaths by 2050.\[1\] The
results reflect the overall findings that crash rates, and deaths in
particular, have increased in recent years.\[2\] But beyond high-level
aggregate analysis, the paper shows how road crash data can be
disaggregated in many ways, including by casualty type (e.g. age,
gender), time and location. Although many interesting results have been
generated, the truth is that this paper only really scratches the
surface of what is possible with the 68 columns and hundreds of
thousands of roads of the joined STATS19 data.

This suggests many future areas of research. From a policy perspective,
can automated summary graphics provide insight into performance and
early warnings of increases in certain types of crashes? Can recent
findings about the effectiveness of different interventions, particuarly
around 20 mph zones and limits (Grundy et al. 2009; Aldred et al. 2018)
be replicated using open data and publicly available code?

From a GIS perspective, the data presented in this paper are undoubtedly
of great interest in terms of their size (there are several million
points in the open STATS19 data, going back to 1979), richness (with 50+
variables across 3 tables which can be judiciously joined) and spatial
resolution (around 10m, although this has not been verified). This
raises further questions about interactive data visualisation, for
example using the `geoplumber` package, which builds on `plumber`
(Trestle Technology, LLC 2018), and the possibility for web applications
building on sites such as
[www.crashmap.co.uk](https://www.crashmap.co.uk/). Although more
theoretical directions are suggested by the complex processes that
result in crashes (point patterns on a linear network), the
recommendation from this paper is that future academic work is driven
primarily by policy need.

# References

<div id="refs" class="references">

<div id="ref-aldred_cycling_2018">

Aldred, Rachel, Anna Goodman, John Gulliver, and James Woodcock. 2018.
“Cycling Injury Risk in London: A Case-Control Study Exploring the
Impact of Cycle Volumes, Motor Vehicle Volumes, and Road Characteristics
Including Speed Limits.” *Accident Analysis & Prevention* 117 (August):
75–84. <https://doi.org/10.1016/j.aap.2018.03.003>.

</div>

<div id="ref-bonney_next_2014">

Bonney, Rick, Jennifer L. Shirk, Tina B. Phillips, Andrea Wiggins, Heidi
L. Ballard, Abraham J. Miller-Rushing, and Julia K. Parrish. 2014. “Next
Steps for Citizen Science.” *Science* 343 (6178): 1436–7.
<https://doi.org/10.1126/science.1251554>.

</div>

<div id="ref-STATS19Data">

Department for Transport. 2017. “Road Safety Data.”

</div>

<div id="ref-elvik_handbook_2009">

Elvik, Rune, Truls Vaa, Alena Erke, and Michael Sorensen. 2009. *The
Handbook of Road Safety Measures*. Emerald Group Publishing.

</div>

<div id="ref-grundy_effect_2009">

Grundy, Chris, Rebecca Steinbach, Phil Edwards, Judith Green, Ben
Armstrong, and Paul Wilkinson. 2009. “Effect of 20 Mph Traffic Speed
Zones on Road Injuries in London, 1986-2006: Controlled Interrupted Time
Series Analysis.” *BMJ* 339 (December): b4469.
<https://doi.org/10.1136/bmj.b4469>.

</div>

<div id="ref-kim_using_1996">

Kim, Karl, and Ned Levine. 1996. “Using GIS to Improve Highway Safety.”
*Computers, Environment and Urban Systems* 20 (4-5): 289–302.

</div>

<div id="ref-lovelace_stats19_2019">

Lovelace, R, M Morgan, L Hama, and M Padgham. 2019. “Stats19: A Package
for Working with Open Road Crash Data.” *Journal of Open Source
Software*. <https://doi.org/10.21105/joss.01181>.

</div>

<div id="ref-lovelace_geocomputation_2019">

Lovelace, Robin, Jakub Nowosad, and Jannes Meunchow. 2019.
*Geocomputation with R*. CRC Press.

</div>

<div id="ref-pebesma_simple_2018-1">

Pebesma, Edzer. 2018. “Simple Features for R: Standardized Support for
Spatial Vector Data.” *The R Journal* 10 (1): 439–46.

</div>

<div id="ref-peled_pc-oriented_1993">

Peled, Ammatzia, and A. Shalom Hakkert. 1993. “A PC-Oriented GIS
Application for Road Safety Analysis and Management.” *Traffic
Engineering & Control* 34 (8).

</div>

<div id="ref-razzak_application_2011">

Razzak, Junsid, Uzma R. Khan, and Sabeena Jalal. 2011. “Application of
Geographical Information System (GIS) for Mapping Road Traffic Injuries
Using Existing Source of Data in Karachi, Pakistana Pilot Study.”
*Journal of the Pakistan Medical Association* 61 (7): 640.

</div>

<div id="ref-rcore">

R Core Team. 2019. “R: A Language and Environment for Statistical
Computing.” Vienna, Austria: R Foundation for Statistical Computing.

</div>

<div id="ref-steenberghen_intra-urban_2004">

Steenberghen, Thérèse, T. Dufays, Isabelle Thomas, and Benoît Flahaut.
2004. “Intra-Urban Location and Clustering of Road Accidents Using GIS:
A Belgian Example.” *International Journal of Geographical Information
Science* 18 (2): 169–81.

</div>

<div id="ref-plumber">

Trestle Technology, LLC. 2018. “Plumber: An API Generator for R,” June.

</div>

<div id="ref-vicente-saez_open_2018">

Vicente-Saez, Ruben, and Clara Martinez-Fuentes. 2018. “Open Science
Now: A Systematic Literature Review for an Integrated Definition.”
*Journal of Business Research* 88 (July): 428–36.
<https://doi.org/10.1016/j.jbusres.2017.12.043>.

</div>

<div id="ref-xie_r_2018">

Xie, Yihui, J. J. Allaire, and Garrett Grolemund. 2018. *R Markdown: The
Definitive Guide*. 1 edition. Boca Raton: Chapman and Hall/CRC.

</div>

</div>

1.  
    <https://fleetworld.co.uk/uk-falling-behind-on-road-safety-targets/>

2.   <http://www.brake.org.uk/facts-resources/1653-uk-road-casualties>
