#!/usr/bin/env python3
"""A module for simulating a lemonade stand.

To start the module from the REPL, import using:
    >>> from lemonade import start_lemonade
    >>> help(start_lemonade)
    >>> start_lemonade()
    
.SYNOPSIS
Implements a lemonade stand simulation.

.DESCRIPTION
You've decided to run a lemonade stand on each Saturday of the Summer.
Purchase your inventory of cups, lemons and sugar from the grocery store.
Price your lemonade based on the cost of ingredients, weather forecast, etc.
Lowering your prices will sell more lemonade but return less on each sale.
You might be able to sell more lemonade on hot days at higher prices.
Try to maximize your profits before the Summer ends.

Currency units are selected based on the current computer locale.

Please consider giving to cancer research.

.PARAMETER title
Specifies an alternate title for the lemonade stand.

.PARAMETER celsius
When True, displays the temperature as Celsius.

.PARAMETER noglyphs
When True, the weather glyphs will not be displayed.

.PARAMETER nowait
When True, skips the "now serving" wait loop.

.INPUTS
None.

.OUTPUTS
A whole lot of fun.

.EXAMPLE 
start_lemonade()
Starts a new lemonade stand.

.EXAMPLE 
start_lemonade(title="Penny's Lemonade")
Starts a new lemonade stand, with an alternate title value.
The title value can be up to 30 characters in length.

.EXAMPLE 
start_lemonade(celsius=True)
Starts a new lemonade stand, using Celsius as the temperature scale.

.EXAMPLE 
start_lemonade(noglyphs=True)
Starts a new lemonade stand, without displaying the weather glyphs.
Older console windows may not fully support these UTF8 encoded characters.

.EXAMPLE 
start_lemonade(nowait=True)
Starts a new lemonade stand, skipping the "now serving" wait loop.

.NOTES
MIT License

Copyright (c) 2023 TigerPointe Software, LLC

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

Most console windows support UTF8 encoding.  If you do not see the weather
glyphs (such as the clouds, rain or sun), your console window most likely does
not have UTF8 encoding enabled.  Be sure to start the game with the "noglyphs"
option enabled to avoid displaying the invalid character symbols. 

Dedicated to fond memories of "Lemonade Stand" on the Commodore 64.
If you enjoy this software, please do something kind for free.

History:
01.00 2023-Jan-07 Scott S. Initial release.
01.01 2023-Jan-18 Scott S. Removed extra parenthesis from calculations.
02.00 2023-Jan-22 Scott S. Revised sales calculation, added best price.

.LINK
https://en.wikipedia.org/wiki/Lemonade_Stand

.LINK
https://en.wikipedia.org/wiki/ASCII_art

.LINK
https://braintumor.org/

.LINK
https://www.cancer.org/
"""

from collections import OrderedDict   # ordered dictionaries
from os import system, name           # operating system specific
from random import randrange, uniform # random numbers
from types import SimpleNamespace     # namespaces support

import locale # culture specific locale
import math   # math functions
import re     # regular expressions
import time   # time functions

# Set all of the locale category elements as default
# ex. print(locale.currency(12345.67, grouping=True))
locale.setlocale(locale.LC_ALL, '')

# Define the ASCII art (original image by Scott S.)
# (escapes backslashes and double-quotes)
ascii = """
 .===================.
 |  FRESH  LEMONADE  |
 '==================='
   !!             !!
   !!             !!
   !!             !!
   !!             !!
   !!             !!
   !!             !!
   !!  ______     !!
   !!  \\..../     !!
   !!  (::::)O    !!
=======================
 \\___________________/
  | | | | | | | | | |
  | | | | | | | | | |
  | | | | | | | | | |
  | | | | | | | | | |
 v| | | | | | | | | |v
'\"'\"'\"'\"'\"'\"'\"'\"'\"'\"'\"'
"""


def clear():
    """Clears the screen, works across all platforms.
    """
    if (name == 'nt'):
        _ = system('cls')   # Microsoft Windows
    else:
        _ = system('clear') # All others


def get_sales_amount(potential, unit, price):
    """Gets the sales amount.
    Multiply the potential sales by a ratio of unit cost to actual price; the
    exponent results in the values falling along a curve, rather than along a
    straight line, resulting in more realistic sales values at each price.
    Parameters
    potential : Potential sales
    unit      : Unit cost
    price     : Actual price
    """
    return math.floor(potential * (unit / (price ** 1.5)))


def start_lemonade(title="Lemonade Stand", celsius=False, \
                   noglyphs=False, nowait=False):
    """Starts a new lemonade stand.
    Parameters
    title    : Specifies the title of the lemonade stand
    celsius  : Use Celsius as the temperature scale
    noglyphs : Do not display the weather glyphs (limited UTF8 console support)
    nowait   : Skip the "now serving" wait loop
    """
    
    # Get the ASCII art information
    lines = ascii.splitlines()
    del lines[0]                       # Delete the initial blank line
    width = len(lines[len(lines) - 1]) # Longest line of the ASCII image

    # Define the temperature unit symbols
    fahrenheit_unit = "ºF"
    celsius_unit    = "ºC"

    # Inventory data (contains the item levels)
    inventoryd = {
        'cups'   : 0,
        'lemons' : 0,
        'sugar'  : 0,
        'cash'   : 30.00,
        'start'  : 0.00
    }
    inventory = SimpleNamespace(**inventoryd)
    inventory.start = inventory.cash

    # Cups data (includes a calculated cost per unit)
    cupsd = {
        'cost'  : 2.50, # current price
        'count' : 25,   # servings per box
        'min'   : 0.99, # minimum price
        'unit'  : 0.00  # unit price
    }
    cups = SimpleNamespace(**cupsd)
    cups.unit = round(cups.cost / cups.count, 2)

    # Lemons data (includes a calculated cost per unit)
    lemonsd = {
        'cost'  : 4.00, # current price
        'count' : 8,    # servings per bag
        'min'   : 2.00, # minimum price
        'unit'  : 0.00  # unit price
    }
    lemons = SimpleNamespace(**lemonsd)
    lemons.unit = round(lemons.cost / lemons.count, 2)

    # Sugar data (includes a calculated cost per unit)
    sugard = {
        'cost'  : 3.00, # current price
        'count' : 15,   # servings per bag
        'min'   : 1.50, # minimum price
        'unit'  : 0.00  # unit price
    }
    sugar = SimpleNamespace(**sugard)
    sugar.unit  = round(sugar.cost / sugar.count, 2)

    # Weeks data (measures the session duration)
    weeksd = {
        'current' : 1,   # start with the 1st week
        'total'   : 12,  # span the 12 weeks of Summer
        'sales'   : 99,  # 99 maximum sales per week
        'summary' : []   # empty array
    }
    weeks = SimpleNamespace(**weeksd)

    # Forecast data (includes percentage values, UTF8 glyphs and display names)
    forecastd = OrderedDict()
    forecastd['sunny']  = [1.00, 0x2600, "Sunny"]
    forecastd['partly'] = [0.90, 0x26C5, "Partly Sunny"]
    forecastd['cloudy'] = [0.70, 0x2601, "Mostly Cloudy"]
    forecastd['rainy']  = [0.40, 0x2602, "Rainy"]
    forecastd['stormy'] = [0.10, 0x26C8, "Stormy"]

    # Temperature data (uses Fahrenheit as the percentage values)
    temperatured = {
        'min'      : 69,
        'max'      : 100,
        'units'    : fahrenheit_unit,
        'forecast' : None,
        'value'    : None
    }
    temperature = SimpleNamespace(**temperatured)

    # Score data (based on actual vs. maximum net sales)
    scored = {
        'value' : 0.00,
        'total' : 0.00
    }
    score = SimpleNamespace(**scored)

    # Sanity check the title
    if (title is None) or (len(title.strip()) < 1):
        title = ""
    elif (len(title.strip()) > 30):
        title = title.strip()[0:30] + "... "
    else:
        title = title.strip() + " "

    # Check for Celsius
    if (celsius):
        temperature.units = celsius_unit

    # Start the main loop
    while (weeks.current <= weeks.total):

        # Create a new display buffer for the text messages
        clear()
        buffer = [None] * len(lines)
 
        # Display the current week number
        buffer[0] = ""
        buffer[1] = title + "Week #" + str(weeks.current)

        # Generate a random weather forecast and temperature
        temperature.forecast = randrange(0, len(forecastd))
        temperature.value = randrange(temperature.min, temperature.max)
        formatted = str(temperature.value)
        if (temperature.units == celsius_unit):
            formatted = str(round(((temperature.value - 32) * (5/9))))
        glyph = ""
        if (not noglyphs):
            glyph = chr(forecastd[list(forecastd)[temperature.forecast]][1])
        buffer[2] = ""
        buffer[3] = "Weather Forecast:  " + \
                    formatted + temperature.units + " " + \
                    forecastd[list(forecastd)[temperature.forecast]][2] + \
                    " " + glyph

        # Calculate the potential sales as a percentage of the maximum value
        # (lower temperature = fewer sales, severe weather = fewer sales)
        forecast  = forecastd[list(forecastd)[temperature.forecast]][0]
        potential = math.floor(weeks.sales * \
                               (temperature.value / 100) * \
                               forecast)
        buffer[4] = "Estimated Sales:   " + str(potential) + " cups"

        # Update the cups cost
        cups.cost = cups.cost + round(uniform(-1.50, 1.50), 2)
        if (cups.cost < cups.min):
            cups.cost = cups.min
        cups.unit = round(cups.cost / cups.count, 2)

        # Update the lemons cost
        lemons.cost = lemons.cost + round(uniform(-1.50, 1.50), 2)
        if (lemons.cost < lemons.min):
            lemons.cost = lemons.min
        lemons.unit = round(lemons.cost / lemons.count, 2)

        # Update the sugar cost
        sugar.cost = sugar.cost + round(uniform(-1.50, 1.50), 2)
        if (sugar.cost < sugar.min):
            sugar.cost = sugar.min
        sugar.unit = round(sugar.cost / sugar.count, 2)

        # Display the updated item prices
        buffer[5] = ""
        buffer[6] = "Grocery Store Prices"
        buffer[7] = "  Cups:    " + \
                    locale.currency(cups.cost, grouping=True) + \
                    " box of " + str(cups.count)
        buffer[8] = "  Lemons:  " + \
                    locale.currency(lemons.cost, grouping=True) + \
                    " bag of " + str(lemons.count)
        buffer[9] = "  Sugar:   " + \
                    locale.currency(sugar.cost, grouping=True) + \
                    " bag for " + str(sugar.count) + " cups"

        # Calculate the unit cost
        unit = cups.unit + lemons.unit + sugar.unit
        buffer[10] = "           " + \
                     locale.currency(unit, grouping=True) + \
                     " cost per serving"

        # Display the current inventory
        buffer[11] = ""
        buffer[12] = "My Current Inventory"
        buffer[13] = "  Cups:    " + str(inventory.cups)
        buffer[14] = "  Lemons:  " + str(inventory.lemons)
        buffer[15] = "  Sugar:   " + str(inventory.sugar)

        # Display the current cash
        gainloss   = inventory.cash - inventory.start
        buffer[16] = ""
        buffer[17] = "My Cash:    " + \
                     locale.currency(inventory.cash, grouping=True)
        buffer[18] = "Gain/Loss:  " + \
                     locale.currency(gainloss, grouping=True)
        buffer[19] = ""
        
        # Output the display buffer
        # (combines the ASCII art with the text messages)
        for i in range(len(buffer)):
            print(lines[i].ljust(width) + "  " + buffer[i])

        # Read the number of cup boxes to purchase
        newcups = -1
        while (newcups < 0):
            try:
                newcups = int(input("How many boxes of cups to buy? ") or 0)
                if (newcups > 0):
                    cost = newcups * cups.cost
                    if (cost > inventory.cash):
                        raise Exception("You do not have enough cash.")
                    inventory.cups += (newcups * cups.count)
                    inventory.cash -= cost
                    print("  Purchased " + str(newcups) + \
                          " box(es) of cups for " + \
                          locale.currency(cost, grouping=True))
                    print("  " + \
                          str(inventory.cups) + " cup inventory, "  + \
                          locale.currency(inventory.cash, grouping=True) + \
                          " cash remaining")
                else:
                    print("  No additional cups were purchased")
            except Exception as e:
                print("  " + str(e))
                newcups = -1

        # Read the number of lemon bags to purchase
        newlemons = -1
        while (newlemons < 0):
            try:
                newlemons = int(input("How many bags of lemons to buy? ") or 0)
                if (newlemons > 0):
                    cost = newlemons * lemons.cost
                    if (cost > inventory.cash):
                        raise Exception("You do not have enough cash.")
                    inventory.lemons += (newlemons * lemons.count)
                    inventory.cash   -= cost
                    print("  Purchased " + str(newlemons) + \
                          " bag(s) of lemons for " + \
                          locale.currency(cost, grouping=True))
                    print("  " + \
                          str(inventory.lemons) + " lemon inventory, "  + \
                          locale.currency(inventory.cash, grouping=True) + \
                          " cash remaining")
                else:
                    print("  No additional lemons were purchased")
            except Exception as e:
                print("  " + str(e))
                newlemons = -1

        # Read the number of sugar bags to purchase
        newsugar = -1
        while (newsugar < 0):
            try:
                newsugar = int(input("How many bags of sugar to buy? ") or 0)
                if (newsugar > 0):
                    cost = newsugar * sugar.cost
                    if (cost > inventory.cash):
                        raise Exception("You do not have enough cash.")
                    inventory.sugar += (newsugar * sugar.count)
                    inventory.cash  -= cost
                    print("  Purchased " + str(newsugar) + \
                          " bag(s) of sugar for " + \
                          locale.currency(cost, grouping=True))
                    print("  " + \
                          str(inventory.sugar) + " sugar inventory, "  + \
                          locale.currency(inventory.cash, grouping=True) + \
                          " cash remaining")
                else:
                    print("  No additional sugar was purchased")
            except Exception as e:
                print("  " + str(e))
                newsugar = -1

        # Read the actual price
        price = 0.00
        while (price <= 0.00):
            try:
                raw   = input("How much should the lemonade cost? ")
                price = float(re.sub("[^0-9.-]", "", raw) or 0.00)
                if (price <= 0.00):
                    raise Exception("The price must be greater than zero.")
            except Exception as e:
                print("  " + str(e))
                price = 0.00
        print("  Setting the price at " + \
              locale.currency(price, grouping=True))

        # Calculate the weekly sales based on price and lowest inventory level
        # (higher markup price = fewer sales, limited by the inventory on-hand)
        sales  = get_sales_amount(potential, unit, price)
        sales  = min(potential, sales, \
                     inventory.cups, inventory.lemons, \
                     inventory.sugar) # "min" returns lowest value
        margin = price - unit
        gross  = sales * price
        net    = sales * margin
        
        # Add a new row to the summary
        weeks.summary.append({ 'sales' : sales, 'price' : price })

        # Simulate a sense of time passing (each dot represents a sale)
        if (not nowait):
            print("\nNow Serving:")
            for i in range(sales):
                print(". ", end="", flush=True)
                time.sleep(randrange(250, 1500) / 1000) # convert milliseconds
            print()
                
        # Update the inventory levels to reflect consumption
        inventory.cups   = inventory.cups   - sales
        inventory.lemons = inventory.lemons - sales
        inventory.sugar  = inventory.sugar  - sales
        inventory.cash   = inventory.cash   + gross
        gainloss         = inventory.cash   - inventory.start
  
        # Display the calculated sales information
        clear()
        print("\nSales Results Week #" + \
              str(weeks.current) + " of " + str(weeks.total))
        print("  Unit Cost (per serving):  " + \
              locale.currency(unit, grouping=True))
        print("  Actual Price:             " + \
              locale.currency(price, grouping=True))
        print("  Profit Margin:            " + \
              locale.currency(margin, grouping=True))
        print("  Actual Sales:             " + \
              str(sales) + " x " + locale.currency(price, grouping=True))
        print("  Gross Profit:             " + \
              locale.currency(gross, grouping=True))
        print("  Net Profit:               " + \
              locale.currency(net, grouping=True))
        print("  Current Cash:             " + \
              locale.currency(inventory.cash, grouping=True))
        print("  Total Gain/Loss:          " + \
              locale.currency(gainloss, grouping=True))
        
        # Display the updated inventory levels
        print("\nRemaining Inventory")
        print("  Cups:                     " + str(inventory.cups))
        print("  Lemons:                   " + str(inventory.lemons))
        print("  Sugar:                    " + str(inventory.sugar))
  
        # Display the weekly sales summary
        pad_week = len(str(weeks.total))
        pad_sale = len(str(weeks.sales))
        total    = 0
        print("\nWeekly Sales Summary")
        for i in range(len(weeks.summary)):
            print("  Week " + str(i + 1).rjust(pad_week) + ":  " + \
                  str(weeks.summary[i]['sales']).rjust(pad_sale) + \
                  " sold x " + \
                  locale.currency(weeks.summary[i]['price'], grouping=True) + \
                  " ea.")
            total = total + weeks.summary[i]['sales']

        # Loop through a range of prices to find the highest net profit
        maxsales = 0
        maxprice = 0.00
        maxgross = 0.00
        maxnet   = 0.00
        minnet   = net
        for i in range(25, 2500, 25):
            price  = i / 100 # range uses integers, not currency (floats)
            sales  = get_sales_amount(potential, unit, price)
            margin = price - unit
            gross  = sales * price
            net    = sales * margin
            if (sales  >  0) and \
                (sales <= potential) and \
                (unit  <= price):
                    if (net > maxnet):
                        maxsales = sales
                        maxprice = price
                        maxgross = gross
                        maxnet   = net
        if (maxnet > minnet):
            print("\nYour sales could have been:")
            print("  " + str(maxsales) + " sold x " + \
                  locale.currency(maxprice, grouping=True) + \
                  " ea. = " + \
                  locale.currency(maxgross, grouping=True) + \
                  " for a net profit of " + \
                  locale.currency(maxnet, grouping=True))
            if (inventory.cups <= 0):
                print("  You ran out of cups.")
            if (inventory.lemons <= 0):
                print("  You ran out of lemons.")
            if (inventory.sugar <= 0):
                print("  You ran out of sugar.")
        else:
            print("\nCongratulations -- your sales were perfect!")

        # Increment the score counters
        score.value = score.value + minnet
        score.total = score.total + maxnet

        # Increment the week number
        if (weeks.current == weeks.total):
            success = round((score.value / score.total) * 100)
            print("\nYou've made " + \
                  locale.currency(score.value, grouping=True) + \
                  " out of a possible " + \
                  locale.currency(score.total, grouping=True) + \
                  " for a score of " + str(success) + "%")
            print("You've sold " + str(total) + \
                  " total cups -- see you again next time!")
        weeks.current = weeks.current + 1
        input("\nPress ENTER to Continue")


# Start the module interactively
if __name__ == "__main__":
    start_lemonade(celsius=False, noglyphs=False, nowait=False)
