## ------------------------------------------------------------------------
pkgs = c(
  "tidyverse",
  "sf",
  "stats19",
  "tmap"
)

## ---- eval=FALSE---------------------------------------------------------
## install.packages(pkgs)
## purrr::map_lgl(pkgs, require, character.only = TRUE)

## ---- echo=FALSE, message=FALSE------------------------------------------
setNames(purrr::map_lgl(pkgs, require, character.only = TRUE), pkgs)

## ----cached1, cache=TRUE, message=FALSE, eval=FALSE----------------------
## y = 2013:2017
## a = map_dfr(y, get_stats19, type = "accidents", ask = FALSE)

## ---- echo=FALSE, eval=FALSE---------------------------------------------
## saveRDS(a, "documents/gisruk/a.Rds")

## ---- eval=FALSE---------------------------------------------------------
## a_sf = format_sf(a)
## a_sample = a_sf %>% sample_n(1000)

## ---- echo=FALSE---------------------------------------------------------
# saveRDS(a_sample, "documents/gisruk/a_sample.Rds")
download.file("https://github.com/Robinlovelace/stats19-gisruk/releases/download/0.0.1/a_sample.Rds", "a_sample.Rds")
a_sample = readRDS("a_sample.Rds")

## ----uk-plot1, cache=TRUE, fig.cap="Columns of 'a_sample' variable plotted separately on a UK map.", warning=FALSE, fig.height=4----
plot(a_sample)

## ---- eval=FALSE---------------------------------------------------------
## c = map_dfr(y, get_stats19, type = "casualties", ask = FALSE)
## v = map_dfr(y, get_stats19, type = "vehicle", ask = FALSE)

## ---- echo=FALSE, cache=TRUE, eval=FALSE---------------------------------
## # note: previous line must be done interactively
## # saveRDS(c, "documents/gisruk/c.Rds")
## # saveRDS(v, "documents/gisruk/v.Rds")
## # c = readRDS("documents/gisruk/c.Rds")
## # v = readRDS("documents/gisruk/v.Rds")
## c = readRDS("c.Rds")
## v = readRDS("v.Rds")

## ---- eval=FALSE---------------------------------------------------------
## c_ped = c %>% filter(casualty_type == "Pedestrian")
## v_car = v %>% filter(vehicle_type == "Car")
## a_cp = a_sf %>%
##   filter(number_of_vehicles == 1 & number_of_casualties == 1) %>%
##   filter(accident_index %in% c_ped$accident_index) %>%
##   filter(accident_index %in% v_car$accident_index)

## ---- eval=FALSE, echo=FALSE---------------------------------------------
## nrow(a_cp) / nrow(a)

## ---- eval=FALSE---------------------------------------------------------
## a_cpj = a_cp %>%
##   inner_join(v_car) %>%
##   inner_join(c_ped)

## ---- echo=FALSE---------------------------------------------------------
u = "https://github.com/Robinlovelace/stats19-gisruk/releases/download/0.0.1/a_cpj.Rds"
f = "a_cpj.Rds"
if(!file.exists(f)) download.file(url = u, destfile = f)
# file.copy("documets/gisruk/a_cpj.Rds", "a_cpj.Rds")
# piggyback::pb_upload("a_cpj.Rds")
# piggyback::pb_download("a_cpj.Rds")
# file.copy("a_cpj.Rds", "documets/gisruk/a_cpj.Rds")

# saveRDS(a_cpj, "documents/gisruk/a_cpj.Rds")
a_cpj = readRDS("a_cpj.Rds")
# a_cpj = readRDS("documents/gisruk/a_cpj.Rds")

## ---- echo=FALSE---------------------------------------------------------
a_cpj$impact = a_cpj$first_point_of_impact
a_cpj$impact[grepl(pattern = "missing|not", x = a_cpj$impact)] = "Other"
a_cpj$age_band_of_casualty[a_cpj$age_band_of_casualty == "6 - 10"] = "06 - 10"

## ------------------------------------------------------------------------
g = ggplot(a_cpj)

## ------------------------------------------------------------------------
p1 = g + geom_bar(aes(accident_severity, fill = urban_or_rural_area)) +
 facet_wrap(vars(speed_limit), scales = "free_y") +
  labs(fill = "Location")
p2 = g + geom_bar(aes(accident_severity, fill = impact)) +
  facet_wrap(vars(age_band_of_casualty), scales = "free_y") +
  theme(axis.text.x = element_text(angle = 45))

## ---- fig.cap="Crash severity by speed limit (top) and crash severity by age band of casualty (bottom)", fig.height=6, echo=FALSE----
# devtools::install_github("thomasp85/patchwork")
library(patchwork)
p1 + p2 + plot_layout(ncol = 1, heights = c(4, 5))

## ---- eval=FALSE, echo=FALSE---------------------------------------------
## # base R plotting
## barplot(table(a_cpj$accident_severity))
## 

## ------------------------------------------------------------------------
agg_slight = aggregate(a_cpj["accident_severity"], police_boundaries,
                      function(x) sum(grepl(pattern = "Slight", x)))

## ---- echo=FALSE, fig.cap="Overview of crashes by police force area, showing relative numbers of slight, serious and fatal injuries.", message=FALSE----
agg_severe = aggregate(a_cpj["accident_severity"], police_boundaries,
                      function(x) sum(grepl(pattern = "Serious", x)))
agg_fatal = aggregate(a_cpj["accident_severity"], police_boundaries,
                      function(x) sum(grepl(pattern = "Fatal", x)))
agg_none = agg_slight[0]
agg_all = agg_none
agg_all$slight = agg_slight$accident_severity
agg_all$serious = agg_severe$accident_severity
agg_all$fatal = agg_fatal$accident_severity
b = 10^(-1:5)
tm_shape(agg_all) +
  tm_polygons(c("slight", "serious", "fatal"), palette = "viridis", breaks = b)

## ---- echo=FALSE---------------------------------------------------------
agg_all$name = police_boundaries$pfa16nm
agg_names = agg_all %>% 
  mutate(percent_fatal = fatal / (slight + serious + fatal) * 100)
# mapview::mapview(agg_names) # verification
top_n = agg_names %>% 
  arrange(desc(percent_fatal)) %>% 
  top_n(5, percent_fatal) %>% 
  st_drop_geometry() %>% 
  dplyr::select(name, slight, serious, fatal, percent_fatal)

bottom_n = agg_names %>% 
  arrange(desc(percent_fatal)) %>% 
  top_n(-5, percent_fatal) %>% 
  st_drop_geometry() %>% 
  dplyr::select(name, slight, serious, fatal, percent_fatal)

na_df = matrix(data = NA, nrow = 1, ncol = ncol(bottom_n)) %>% 
  as.data.frame()
names(na_df) = names(bottom_n)

top_bottom = bind_rows(top_n, na_df, bottom_n)
knitr::kable(top_bottom, digits = 1, caption = "Top and bottom 5 police forces in terms of the percentage of car-pedestrian crashes that are fatal.")

## ---- echo=FALSE, fig.cap="Variability of crash rates over time."--------
a_cpj$year = lubridate::year(a_cpj$date)
a_cpj$month = lubridate::month(a_cpj$date)
a_cpj$pct_yr = a_cpj$month / 13
a_cpj$year_month = a_cpj$year + a_cpj$pct_yr
a_time = a_cpj %>% 
  st_drop_geometry() %>% 
  group_by(year_month, casualty_severity) %>% 
  summarise(n = n())
ggplot(a_time) +
  geom_line(aes(year_month, n, lty = casualty_severity)) +
  scale_y_log10()

## ------------------------------------------------------------------------
a_cps = st_join(a_cpj, police_boundaries)

## ---- echo=FALSE, message=FALSE, fig.cap="Average number of pedestrian casualties by severity and police force in a selection of areas (see Table 1)"----
a_cps$year = lubridate::year(a_cps$date)
a_cps$month = lubridate::month(a_cps$date)
a_cps$pct_yr = a_cps$month / 13
a_cps$year_month = a_cps$year + a_cps$pct_yr
# a_cps$quarter = lubridate::quarter(a_cps$date, with_year = TRUE)
a_cps_sub = a_cps[a_cps$pfa16nm %in% top_bottom$name[7:10], ]
a_time = a_cps_sub %>% 
  st_drop_geometry() %>% 
  group_by(year_month, pfa16nm, casualty_severity) %>% 
  summarise(n = n())
ggplot(a_time) +
  geom_smooth(aes(year_month, n, col = pfa16nm)) +
  facet_wrap(vars(casualty_severity), scales = "free_y") +
  theme(axis.text.x = element_text(angle = 45))
  

## ---- echo=FALSE, fig.cap="Trend in car-pedestrian casualties by region, 2013 to 2017, in units of average number of additional casualties per year, by severity of injuries.", message=FALSE----
region = "Lancashire"
sev = "Fatal"
sel = a_cps$pfa16nm == region
a_cps_sub1 = a_cps[sel, ]
a_agg = a_cps %>% 
  st_drop_geometry() %>% 
  group_by(pfa16nm, year) %>% 
  summarise(
    Fatal = sum(casualty_severity == "Fatal"),
    Serious = sum(casualty_severity == "Serious"),
    Slight = sum(casualty_severity == "Slight")
    )
a_cor = a_agg %>% 
  group_by(pfa16nm) %>% 
  summarise(
    Fatal = lm(Fatal ~ year)$coefficients[2],
    Serious = lm(Serious ~ year)$coefficients[2],
    Slight = lm(Slight ~ year)$coefficients[2]
    )
agg_cor = left_join(police_boundaries, a_cor)
a_highlight = filter(police_boundaries, pfa16nm %in% top_bottom$name[7:10])
a_highlight$nm = stringr::str_sub(string = a_highlight$pfa16nm, start = 1, end = 3)
b = c(60, 5, 1, 0)
bb = c(-b, b[3:1])
tm_shape(agg_cor) +
  tm_fill(c("Fatal", "Serious", "Slight"), palette = "-Spectral", alpha = 0.8, breaks = bb) +
  tm_borders() +
  tm_shape(a_highlight) +
  tm_borders(col = "blue", lwd = 2, alpha = 0.4) +
  tm_text("nm") 
  # tm_layout(legend.outside = T)

