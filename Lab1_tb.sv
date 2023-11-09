// модуль ТЕСТБЕНЧ
`include "Lab1_master.sv"      // подключаем файл МАСТЕРА
`include "Lab1_slave.sv"       // подключаем файл СЛЕЙВА


module Lab1_tb
#(
  parameter number_in_group_ADDR = 0,  // адрес регистра, где хранится номер студента в группе
  parameter data_ADDR = 4,             // адрес регистра, где хранится дата дд.мм.гг
  parameter surname_ADDR = 8,          // адрес регистра, где хранится первые 4 буквы фамилии
  parameter name_ADDR = 4'hC           // адрес регистра, где хранится первые 4 буквы имени
);

reg PCLK = 0;                  // сигнал синхронизации
reg PWRITE_MASTER = 0;         // сигнал, выбирающий режим записи или чтения (1 - запись, 0 - чтение)
wire PSEL;                     // сигнал выбора переферии 
reg [31:0] PADDR_MASTER = 0;   // Адрес регистра
reg [31:0] PWDATA_MASTER = 0;  // Данные для записи в регистр
wire [31:0] PRDATA_MASTER;     // Данные, прочитанные из слейва
wire PENABLE;                  // сигнал разрешения, формирующийся в мастер APB
reg PRESET = 0;                // сигнал сброса
wire PREADY;                   // сигнал готовности (флаг того, что всё сделано успешно)
wire [31:0] PADDR;             // адрес, который мы будем передавать в слейв
wire [31:0] PWDATA;            // данные, которые будут передаваться в слейв,
wire [31:0] PRDATA ;           // данные, прочтённые с слейва
wire PWRITE;                   // сигнал записи или чтения на вход слейва

// создание экземпляра мастера
master Lab1_master_1 (
    .PCLK(PCLK),
    .PWRITE_MASTER(PWRITE_MASTER),
    .PSEL(PSEL),
    .PADDR_MASTER(PADDR_MASTER),
    .PWDATA_MASTER(PWDATA_MASTER),
    .PRDATA_MASTER(PRDATA_MASTER),
    .PENABLE(PENABLE),
    .PRESET(PRESET),
    .PREADY(PREADY),
    .PADDR(PADDR),
    .PWDATA(PWDATA),
    .PRDATA(PRDATA),
    .PWRITE(PWRITE)
);

// создание экземпляра слейва
slave Lab1_slave_1 (
    .PWRITE(PWRITE),
    .PSEL(PSEL),
    .PADDR(PADDR),
    .PWDATA(PWDATA),
    .PRDATA(PRDATA),
    .PENABLE(PENABLE),
    .PREADY(PREADY),
    .PCLK(PCLK)
);

// Объявление задачи для записи данных в регистр
task write_data;
  input reg [31:0] DATA;  // данные для записи
  input reg[31:0] ADDR;   // адрес регистра
  begin

    // Непосредственно операция записи
    PWRITE_MASTER = 1;              // выбираем запись
    PWDATA_MASTER = DATA;           // в данные для записи записываем свое значение
    PADDR_MASTER = ADDR;            // выбираем адрес регистра
  end
endtask

// объявление задачи для чтения данных из регистра
task read_data;
  input reg[31:0] ADDR;
  begin

    // Непосредственно операция чтения
    PWRITE_MASTER = 0;               // выбираем чтение
    PADDR_MASTER = ADDR;             // выбираем адрес для чтения
  end
endtask


initial begin
PCLK = 0;                            // устанавливаем начальное значение тактового сигнала
// сброс output регистров
PRESET = 0;
@(posedge PCLK);
PRESET = 1;
//ЗАПИСЬ
// записываем свой номер в группе
write_data(3, number_in_group_ADDR);
@(posedge PCLK);
@(posedge PCLK);
$display("Writing into address 0x%h record %h", PADDR, PWDATA);

// записываем сегодняшнюю дату
write_data(32'h8112023, data_ADDR);
@(posedge PCLK);
@(posedge PCLK);
$display("Writing into address 0x%h record %h", PADDR, PWDATA);

// записываем четыре первых буквы фамилии в формате ASCII 
write_data(32'h56494B55, surname_ADDR);
@(posedge PCLK);
@(posedge PCLK);
$display("Writing into address 0x%h record %h", PADDR, PWDATA);

// записываем четыре первые буквы имени в формате ASCII 
write_data(32'h444D4954, name_ADDR);
@(posedge PCLK);
@(posedge PCLK);
$display("Writing into address 0x%h record %h", PADDR, PWDATA);


//ЧТЕНИЕ
// читаем записанный номер в группе
read_data(number_in_group_ADDR);
@(posedge PCLK);
@(posedge PCLK);
$display("Reading from address 0x%h record %h", PADDR, PRDATA);

// читаем записанную дату
read_data(data_ADDR);
@(posedge PCLK);
@(posedge PCLK);
$display("Reading from address 0x%h record %h", PADDR, PRDATA);

// читаем записанные первые четыре буквы фамилии в формате ASCII
read_data(surname_ADDR);
@(posedge PCLK);
$display("Reading from address 0x%h record %h", PADDR, PRDATA);

// читаем первые четыре буквы имени в формате ASCII
read_data(name_ADDR);
@(posedge PCLK);
@(posedge PCLK);
$display("Reading from address 0x%h record %h", PADDR, PRDATA);

// Заканчиваем симуляцию
$finish;
end

always #150 PCLK = ~PCLK; // генерация входного сигнала PCLK

// создание файла .vcd и вывести значения переменных волны для отображения в визуализаторе волн
initial begin
$dumpfile("Lab1_tb.vcd");  // создание файла для сохранения результатов симуляции
$dumpvars(0, Lab1_tb);     // установка переменных для сохранения в файле
$dumpvars;
end


endmodule