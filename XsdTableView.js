/**
 * Скрипт автоматически расставляет colspan у ячеек,
 * class которых содержит подстроку, указанную в константе AUTO_EXPANDER_STYLE.
 * Таким образом, все строки таблицы занимают всю её ширину.
 * Кроме того, в ячейки с классом, заданным в константе COUNTER_STYLE,
 * скрипт вставляет номер элемента, с учётом уровня его вложенности.
 * При увеличении уровня вложенности, скрипт меняет стиль ячеек
 * с SIMPLE_ELEMENT_NAME_STYLE на COMPLEX_ELEMENT_NAME_STYLE - чтобы выделить сложные типы.
 */
var AUTO_EXPANDER_STYLE = 'AutoExpanded';
var COUNTER_STYLE = 'counter';
var SIMPLE_ELEMENT_NAME_STYLE = 'elementName';
var COMPLEX_ELEMENT_NAME_STYLE = 'complexElementName';
var MAX_LEVEL_COUNTER = 2;

var WIDTHS = new Array();
WIDTHS[1] = '8mm';
WIDTHS[2] = '12mm';
WIDTHS[3] = '18mm';
WIDTHS[4] = '8mm';

function getWidth(level) {
    return level > 4 ? WIDTHS[4] : WIDTHS[level];
}

function renderTable(table) {
    var quantity = getColumnQuantity(table);
    var rows = table.rows;
    var counter = new Counter();
    var previousLevel = 1;
    var previousRow;

    for (var i = 0; i < rows.length; i++) {
        var row = rows.item(i);
        var rowCells = row.cells.length;
        if (rowCells < quantity) {
            getAutoExpandedCell(row).colSpan = quantity - rowCells + 1;
        }
        var counterCell = getCounterCell(row);
        if(counterCell) {
            var level = getLevel(counterCell);
            if(level) {
                if(level > previousLevel) {
                    counter.levelUp();
                    changeStyleToComplexElement(previousRow);
                } else if (level < previousLevel) {
                    counter.levelDown(previousLevel - level);
                }
                previousLevel = level;
                counter.nextItem();
                counterCell.innerHTML = counter.toString();
                counterCell.style.width = getWidth(level);
            }
        }
        previousRow = row;
    }
}
/**
 * Возвращает первую клетку в заданной строке, class которой содержит подстроку, указанную в константе AUTO_EXPANDER_STYLE.
 * Если такая клетка не находится, возвращает первую клетку строки.
 */
function getAutoExpandedCell(row) {
    var cells = row.cells;
    for (var i = 0; i < cells.length; i++) {
        var cell = cells.item(i);
        if (cell.className && cell.className.indexOf(AUTO_EXPANDER_STYLE) != -1) {
            return cell;
        }
    }
    return cells.item(0);
}
/**
 * Возвращает первую клетку в заданной строке, class которой содержит подстроку, указанную в константе COUNTER_STYLE.
 * Если такая клетка не находится, возвращает null.
 */
function getCounterCell(row) {
    var cells = row.cells;
    for (var i = 0; i < cells.length; i++) {
        var cell = cells.item(i);
        if (cell.className && cell.className.indexOf(COUNTER_STYLE) != -1) {
            return cell;
        }
    }
    return null;
}
/**
 * Если в клетке - целое число (уровень вложенности счётчика), возвращает это число, иначе возвращает null.
 */
function getLevel(cell) {
    try {
        return parseInt(cell.innerHTML);
    } catch (err){
        return null;
    }
}
/**
 * Возвращает количество колонок заданной таблицы.
 * Под количеством колонок понимается максимальное количество ячеек в строках таблицы.
 * colspan ячеек при этом не учитывается!
 */
function getColumnQuantity(table) {
    var rows = table.rows;
    var quantity = 0;
    for (var i = 0; i < rows.length; i++) {
        var rowCells = rows.item(i).cells.length;
        if (quantity < rowCells) {
            quantity = rowCells;
        }
    }
    return quantity;
}

/**
 * Меняет в заданной строке стили клеток с SIMPLE_ELEMENT_NAME_STYLE на COMPLEX_ELEMENT_NAME_STYLE.
 */
function changeStyleToComplexElement(row) {
    if(!row) {
        return;
    }
    var cells = row.cells;
    for (var i = 0; i < cells.length; i++) {
        var cell = cells.item(i);
        if (cell.className && cell.className.indexOf(SIMPLE_ELEMENT_NAME_STYLE) != -1) {
            cell.className = cell.className.replace(SIMPLE_ELEMENT_NAME_STYLE, COMPLEX_ELEMENT_NAME_STYLE);
        }
    }
}

/**
 * Счётчик. Хранит сложный номер строки.
 */
function Counter() {
    this.currentLevel = 0;
    this.currentCount = 0;
    this.upperLevels = new Array();

    this.toString = function() {
        if(this.currentLevel > MAX_LEVEL_COUNTER) {
			return '*.' + this.currentCount;
		}
        var result = '';
        for(var i = 0; i < this.currentLevel; i++) {
            result += (this.upperLevels[i] + '.');
        }
        return result + this.currentCount;
    };

    this.nextItem = function() {
        this.currentCount++;
    };

    this.levelUp = function() {
        this.upperLevels[this.currentLevel] = this.currentCount;
        this.currentLevel++;
        this.currentCount = 0;
    };

    this.levelDown = function(levels) {
        this.currentLevel-= levels;
        this.currentCount = this.upperLevels[this.currentLevel];
    };
}