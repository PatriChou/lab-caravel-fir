# lab-caravel-fir

## Caravel Big picture
![image](https://github.com/PatriChou/lab-caravel-fir/assets/145217252/bdf87c1a-88cf-4c4c-8727-11783b0fa673)

在Caravel SoC的基礎上，再加上自行設計的FIR 硬體，最後透過存在Spiflash的 Firmware Code 去控制FIR。

**其中 mprj_io 是Caravel SoC與外面溝通的橋樑，由於我們是在TestBench 的環境下去驗證FIR，因此在TestBench中 會透過mprj_io來檢查值是否正確。 

## User Project Wrapper
![image](https://github.com/PatriChou/lab-caravel-fir/assets/145217252/b2a442e0-0816-4388-adc9-3f084636bc74)

這部分有三個part:

  WB_DECODER(user_proj_example.counter.v)
    由於EXMEM、WBAXI的地址不同，而CPU只有一組WBS能夠輸出，因此為了能夠去區分這兩組的訊號，
    WB_DECODER會去將CPU的訊號依照傳送的地址的不同，將訊號分別傳送到指定的元件去。
    
  EXMEM(BASE ADDR:38_000_000)
    是用來儲存Firmwave Code的Assembly Code。CPU會先將Spiflash的執行檔讀取到exmem中，之後再從exmem讀取出來執行。

  WBAXI(BASE ADDR:30_000_000)
    由於CPU是使用WBS作為溝通協議，而FIR 的介面則是AXI協議，因此WBAXI 是負責轉接橋梁，讓兩者能夠正常溝通。

## TestBench
  ![image](https://github.com/PatriChou/lab-caravel-fir/assets/145217252/7a3e752b-ee61-4969-a89e-287cefd12087)
    
  在驗證的部分，一共分有七個步驟

  第一步
    等待START SIGNAL(AB40)，這樣做的目的是為了讓Testbench能夠知道FIR的運算是何時開始的。

  第二步
    等待DATA START SIGNAL(FFFF)，這是為了要去區分每一筆DATA所設下的。
    在Firmware Code中，每算一筆新的DATA前，都會先傳送FFFF去告知Testbench，而它的下一筆就會是FIR的運算結果(Y[n])。

  第三步
    等待接收FIR的運算結果(Y[n])，當Checkbit 改變(FFFF -> XXXX)時，代表此時的XXXX 就會是FIR的運算結果(Y[n])。

  第四步
    檢查TEST LENGTH(64)是否有滿足，如果沒有的話重複第二和第三步驟。

  第五步
    檢查這次的運算結果是否正確，並且將結果記錄下來。

  第六步
    檢查TEST LOOP(3)是否有滿足，如果沒有的話重複第二、第三和第四步驟。
    
  第七步
    最後驗證完畢後，就會去印出FINAL REPORT，顯示這次的驗證結果是否通過或失敗。

    
