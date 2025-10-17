@echo off
echo ====================================
echo  Testing DuitNow API Endpoints
echo ====================================
echo.

echo [1/4] Testing Health Check...
curl -s http://localhost:3000/health
echo.
echo.

echo [2/4] Creating Test Order...
curl -s -X POST http://localhost:3000/api/create-order -H "Content-Type: application/json" -d "{\"amount\": 25.50}" > temp_order.json
echo Order created!
echo.

echo [3/4] Reading Order ID...
for /f "tokens=2 delims=:," %%a in ('findstr "orderId" temp_order.json') do set ORDER_ID=%%a
set ORDER_ID=%ORDER_ID:"=%
set ORDER_ID=%ORDER_ID: =%
echo Order ID: %ORDER_ID%
echo.

echo [4/4] Checking Order Status...
curl -s http://localhost:3000/api/order/%ORDER_ID%
echo.
echo.

echo ====================================
echo  Test Complete!
echo ====================================
echo.
echo To simulate payment, run:
echo curl -X POST http://localhost:3000/api/simulate-payment -H "Content-Type: application/json" -d "{\"orderId\": \"%ORDER_ID%\"}"
echo.

del temp_order.json
pause

