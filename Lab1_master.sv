// модуль "МАСТЕР"
module master
(
    input wire PCLK,                     // сигнал синхронизации
    input wire PWRITE_MASTER,            // сигнал, выбирающий режим записи или чтения (1 - запись, 0 - чтение)
    input wire [31:0] PADDR_MASTER,      // адрес регистра
    input wire [31:0] PWDATA_MASTER,     // данные для записи в регистр
    input wire PRESET,                   // сигнал сброса
    input wire PREADY,                   // сигнал готовности (флаг того, что всё сделано успешно)
    input  wire [31:0] PRDATA,           // данные, прочитанные из слейва
    output reg PWRITE,                   // сигнал записи или чтения на вход слейва
    output reg PSEL = 0,                 // сигнал выбора переферии
    output reg [31:0] PRDATA_MASTER = 0, // данные, прочитанные из слейва
    output reg PENABLE = 0,              // сигнал разрешения, формирующийся в мастер APB 
    output reg [31:0] PADDR = 0,         // адрес, который мы будем передавать в слейв
    output reg [31:0] PWDATA             // данные, которые будут передаваться в слейв
);

// запись данных в шину APB
function void apb_write(input  [31:0] inp_addr,        // адрес для записи
                        input  [31:0] inp_data);       // данные для записи
begin
  PADDR = inp_addr;           // передаем адрес на входе мастера в слейв
  PWDATA = inp_data;          // передаём данные в слейв
  PWRITE = 1'd1;              // устанавливаем сигнал на запись
  PSEL = 1'd1;                // выбрано периферийное устройство для записи
  PENABLE = 1'd1;             // разрешаем запись через шину APB

  // когда слейв успешно записал передаваемые данные
  if(PREADY)
   begin
     PSEL = !PSEL;            // убираем периферийное устройство
     PENABLE = !PENABLE;      // запрет на продолжение дальнейших действий
   end
end
endfunction

//функция чтения из слейва
function void apb_read(input [31:0] inp_addr);
begin
  // операция не завершена
  if(!PREADY)
  begin
    PADDR = inp_addr;  // передаем адрес, откуда читаем на входе мастера в слейв
    PWRITE = 1'd0;     // устанавливаем сигнал чтения
    PSEL = 1'd1;       // выбрано периферийное устройство для чтения
    PENABLE = 1'd1;    // разрешаем чтение
  end
  
  // когда слейв завершил операцию чтения
  if(PREADY)
   begin
     PSEL = !PSEL;        // убираем периферийное устройство
     PENABLE = !PENABLE;  // запрет на продолжение дальнейших действий
   end
end
endfunction

// циклы записи и чтения интерфейса APB
always @(posedge PCLK or posedge PRESET) 
begin 
    // сигнал сброса равен 0 - сброс есть. Все выходные регистры сбрасываются
    if (!PRESET) 
    begin
      PADDR <= 32'b0;
      PWDATA <= 32'b0;
      PWRITE <= 1'b0;
      PSEL <= 1'b0;
      PENABLE <= 1'b0;
      PRDATA_MASTER <= 1'b0;
   end
   
   // сигнал сброса отсутствует
   else 
   begin
      if (!PWRITE_MASTER)         // чтение из регистров 
      begin
          apb_read(PADDR_MASTER); // вызов фунции чтения
      end
      else if (PWRITE_MASTER)     // запись в регистры
      begin
          apb_write(PADDR_MASTER, PWDATA_MASTER);
          PRDATA_MASTER <= 1'b0;
      end
   end
end


always @(posedge PREADY)
begin
  if (!PWRITE_MASTER)        // чтение из регистров 
    begin
     PRDATA_MASTER <=PRDATA; // вызов функции чтения
    end
end
endmodule