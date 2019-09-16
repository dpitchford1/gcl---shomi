
////////// CONFIGURE THE COUNTDOWN SCRIPT HERE //////////////////
var month = '10'; //  '*' for next month, '0' for this month or 1 through 12 for the month 
var day = '8'; //  Offset for day of month day or + day  
var hour = 19; //  0 through 23 for the hours of the day
var tz = -4; //  Offset for your timezone in hours from UTC
var lab = 'countdown2'; //  The id of the page entry where the timezone countdown is to show

function start() {
    displayTZCountDown(setTZCountDown(month, day, hour, tz), lab);
}

// **    The start function can be changed if required   **
window.onload = start;

////////// DO NOT EDIT PAST THIS LINE //////////////////

function setTZCountDown(month, day, hour, tz) {
    var toDate = new Date();
    if (month == '*') toDate.setMonth(toDate.getMonth() + 1);
    else if (month > 0) {
        if (month <= toDate.getMonth()) toDate.setYear(toDate.getYear() + 1);
        toDate.setMonth(month - 1);
    }
    if (day.substr(0, 1) == '+') {
        var day1 = parseInt(day.substr(1),10);
        toDate.setDate(toDate.getDate() + day1);
    } else {
        toDate.setDate(day);
    }
    toDate.setHours(hour);
    toDate.setMinutes(0 - (tz * 60));
    toDate.setSeconds(0);
    var fromDate = new Date();
    fromDate.setMinutes(fromDate.getMinutes() + fromDate.getTimezoneOffset());
    var diffDate = new Date(0);
    diffDate.setMilliseconds(toDate - fromDate);
    return Math.floor(diffDate.valueOf() / 1000);
}

// function displayTZCountDown(countdown, tzcd) {
//     if (countdown < 0) document.getElementById(tzcd).innerHTML = "Sorry, you are too late.";
//     else {
//         var secs = countdown % 60;
//         if (secs < 10) secs = '0' + secs;
//         var countdown1 = (countdown - secs) / 60;
//         var mins = countdown1 % 60;
//         if (mins < 10) mins = '0' + mins;
//         countdown1 = (countdown1 - mins) / 60;
//         var hours = countdown1 % 24;
//         if (hours < 10) hours = '0' + hours;
//         var days = (countdown1 - hours) / 24;
//         document.getElementById(tzcd).innerHTML = '<div class="numbers-group">' + '<span class="numbers">' + days + '</span>' + '<span class="h-b number-label">Day' + (days == 1 ? '' : 's') + '</span>' + '</div>' + '<div class="numbers-group">' + '<span class="numbers">' + hours + '</span>' + '<span class="h-b number-label">Hours</span>' + '</div>' + '<div class="numbers-group">' + '<span class="numbers">' + mins + '</span>' + '<span class="h-b number-label">Minutes</span>' + '</div>';
//         setTimeout('displayTZCountDown(' + (countdown - 1) + ',\'' + tzcd + '\');', 999);
//     }
// }