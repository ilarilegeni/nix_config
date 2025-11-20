static const char norm_fg[] = "#adc2b8";
static const char norm_bg[] = "#021E25";
static const char norm_border[] = "#798780";

static const char sel_fg[] = "#adc2b8";
static const char sel_bg[] = "#2F8379";
static const char sel_border[] = "#adc2b8";

static const char urg_fg[] = "#adc2b8";
static const char urg_bg[] = "#B26E4E";
static const char urg_border[] = "#B26E4E";

static const char *colors[][3]      = {
    /*               fg           bg         border                         */
    [SchemeNorm] = { norm_fg,     norm_bg,   norm_border }, // unfocused wins
    [SchemeSel]  = { sel_fg,      sel_bg,    sel_border },  // the focused win
    [SchemeUrg] =  { urg_fg,      urg_bg,    urg_border },
};
