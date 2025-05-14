@app.route("/expiry-date-reader", methods=["GET", "POST"])
def expiry_date_reader():
    uploaded_image = None
    result_image = None
    extracted_dates = []
    standardized_dates = []
    final_date = None

    if request.method == "POST":
        if "image" in request.files:
            image = request.files["image"]
            if image.filename != "":
                filename = secure_filename(image.filename)
                upload_path = os.path.join(filename)
                image.save(filename)
                uploaded_image = filename

                print("Image has been uploaded successfully")
                results = model(upload_path)
                print("Model has been executed successfully")
                print("Results:", results)
                result_filename = f"result_{filename}"
                result_path = os.path.join(result_filename)
                results[0].save(result_path)
                print("Result image has been saved successfully")
                result_image = result_filename
                
                boxes = results[0].boxes.xyxy.cpu().numpy() if hasattr(results[0].boxes, 'xyxy') else []
                img = cv2.imread(upload_path)
                print("Image has been read successfully")
                print("Boxes:", boxes)
                cropped_images = []
                for box in boxes:
                    x1, y1, x2, y2 = map(int, box)
                    crop = img[y1:y2, x1:x2]
                    if crop.size > 0:
                        cropped_images.append(crop)

                for crop in cropped_images:
                    crop_rgb = cv2.cvtColor(crop, cv2.COLOR_BGR2RGB)
                    ocr_result = ocr.ocr(crop_rgb, cls=True)
                    for line in ocr_result[0]:
                        text = line[1][0]
                        extracted_dates.append(text)
                        print("Extracted text:", text)
                        std_date = standardize_date(text)
                        print("Standardized date:", std_date)
                        if std_date:
                            standardized_dates.append(std_date)

                if standardized_dates:
                    try:
                        date_objs = [datetime.strptime(d, "%Y-%m-%d") for d in standardized_dates]
                        max_date = max(date_objs)
                        final_date = max_date.strftime("%Y-%m-%d")
                        print("Final date:", final_date)
                    except Exception:
                        final_date = standardized_dates[0]

    return {
        "uploaded_image": uploaded_image,
        "result_image": result_image,
        "extracted_dates": extracted_dates,
        "standardized_dates": standardized_dates,
        "final_date": final_date
    }