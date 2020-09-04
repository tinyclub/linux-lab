#ifndef __LDT_COMMON_H__
#define __LDT_COMMON_H__

/* With Linux 3.8 the __devinit macro and others were removed from <linux/init.h>
   Defining them as empty here to keep the other code portable to older kernel versions. */

#include <linux/init.h>

#ifndef __devinit

    #define __devinit
    #define __devinitdata
    #define __devinitconst
    #define __devexit
    #define __devexitdata
    #define __devexitconst

    #if defined(MODULE) || defined(CONFIG_HOTPLUG)
    #define __devexit_p(x) x
    #else
    #define __devexit_p(x) NULL
    #endif

#endif

#endif
