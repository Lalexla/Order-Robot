*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.Excel.Files
Library           RPA.PDF
Library           RPA.Tables
Library           RPA.Archive
Library           RPA.Robocorp.Vault
Library           RPA.Dialogs

*** Variables ***
${RETRY_AMOUNT} =    5x
${RETRY_INTERVAL} =    0.5
${ROBO_OUTPUT_DIR} =    ${OUTPUT_DIR}${/}RoboReceits${/}

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Confirmation dialog
    ${cookieset}=    Get Secret    cookie
    ${table}=    Wait Until Keyword Succeeds    3x    0.5 sec    Get orders
    ${table}=    Read table from CSV    orders.csv
    #Wait Until Keyword Succeeds    ${RETRY_AMOUNT}    ${RETRY_INTERVAL} sec    Run Loop    ${table}    ${cookieset}
    FOR    ${row}    IN    @{table}
        Close modal    ${cookieset}
        Fill the form    ${row}
        Robot snapshot    ${row}[Order number]
        Wait Until Keyword Succeeds    ${RETRY_AMOUNT}    ${RETRY_INTERVAL} sec    Submit the order
        ${pdf} =    Receipt as a PDF file    ${row}[Order number]
        Snapshot to pdf file    ${row}[Order number]    ${pdf}
        Wait Until Keyword Succeeds    ${RETRY_AMOUNT}    ${RETRY_INTERVAL} sec    Order next bot
    END
    Create a ZIP file of the receipts
    [Teardown]    Log out and close the browser

Minimal task
    Log    Done.

*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Close modal
    [Arguments]    ${cookieset}
    Click Button    ${cookieset}[cookieselect]

Run Loop
    [Arguments]    ${table}    ${cookieset}
    FOR    ${row}    IN    @{table}
        Close modal    ${cookieset}
        Fill the form    ${row}
        Robot snapshot    ${row}[Order number]
        Wait Until Keyword Succeeds    ${RETRY_AMOUNT}    ${RETRY_INTERVAL} sec    Submit the order
        ${pdf} =    Receipt as a PDF file    ${row}[Order number]
        Snapshot to pdf file    ${row}[Order number]    ${pdf}
        Wait Until Keyword Succeeds    ${RETRY_AMOUNT}    ${RETRY_INTERVAL} sec    Order next bot
    END

Get orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${table}=    Read table from CSV    orders.csv
    [Return]    ${table}

Create a ZIP file of the receipts
    Archive Folder With Zip    ${OUTPUT_DIR}${/}RoboReceits    robots.zip

Fill the form
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]    1
    Select Radio Button    body    ${row}[Body]
    Input Text    (//input[@class='form-control'])[1]    ${row}[Legs]
    Input Text    address    ${row}[Address]

Robot snapshot
    [Arguments]    ${order}
    Click Button    Preview
    Wait Until Element Is Visible    id:robot-preview-image
    Wait Until Element Is Visible    //img[@alt='Head']
    Wait Until Element Is Visible    //img[@alt='Body']
    Wait Until Element Is Visible    //img[@alt='Legs']
    Screenshot    robot-preview-image    ${ROBO_OUTPUT_DIR}${order}_order.png

Submit the order
    Click Button    Order
    Wait Until Element Is Visible    id:order-another

Order next bot
    Wait Until Element Is Visible    id:order-another
    Click Button When Visible    //button[@id="order-another"]

Receipt as a PDF file
    [Arguments]    ${order}
    ${receipt_html} =    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${ROBO_OUTPUT_DIR}${order}_receipt.pdf
    [Return]    ${ROBO_OUTPUT_DIR}${order}_receipt.pdf

Snapshot to pdf file
    [Arguments]    ${order}    ${pdf}
    Add Watermark Image To PDF
    ...    image_path=${ROBO_OUTPUT_DIR}${order}_order.png
    ...    source_path=${pdf}
    ...    output_path=${pdf}

Log out and close the browser
    Close Browser

Confirmation dialog
    Add icon    Warning
    Add heading    Accept Cookies?
    Add submit buttons    buttons=No,Yes    default=Yes
    ${result}=    Run dialog
    IF    $result.submit == "No"
        Log out and close the browser
    END
