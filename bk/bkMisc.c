/******************************* LICENCE **************************************
* Any code in this file may be redistributed or modified under the terms of
* the GNU General Public Licence as published by the Free Software 
* Foundation; version 2 of the licence.
****************************** END LICENCE ***********************************/

/******************************************************************************
* Author:
* Andrew Smith, http://littlesvr.ca/misc/contactandrew.php
*
* Contributors:
* 
******************************************************************************/

#include <time.h>

#include "bkInternal.h"
#include "bkMisc.h"

void maybeUpdateProgress(VolInfo* volInfo)
{
    struct timeval timeNow;
    
    if(volInfo->progressFunction == NULL)
        return;
    
    gettimeofday(&timeNow, NULL);
    
    if(timeNow.tv_sec - volInfo->lastTimeCalledProgress.tv_sec >= 1 ||
       timeNow.tv_usec - volInfo->lastTimeCalledProgress.tv_usec >= 100000)
    {
        volInfo->progressFunction(volInfo);
        
        volInfo->lastTimeCalledProgress = timeNow;
    }
}
