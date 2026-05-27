
# AWS Lambda Python base image (boto3 is included in the runtime).
FROM public.ecr.aws/lambda/python:3.13
 
# Copy the function code into the Lambda task root.
COPY ssc_cbrid_lambda_function.py ${LAMBDA_TASK_ROOT}/lambda_function.py
 
# Handler: <module>.<function>
CMD [ "lambda_function.lambda_handler" ]