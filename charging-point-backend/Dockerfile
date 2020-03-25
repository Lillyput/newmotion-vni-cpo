FROM python:3.6

RUN pip install websocket-server flask
ADD health_check.py .
ADD server.py .

CMD ["python","-u","server.py"]