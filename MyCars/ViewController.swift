//
//  ViewController.swift
//  MyCars
//

import UIKit
import CoreData

class ViewController: UIViewController {
    
  //получаем наш контекст
  var context: NSManagedObjectContext!
    
    
  var selectedCar: Car!
  //  lazy var context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
  
    //просто ссылки на наши обекты
  @IBOutlet weak var segmentedControl: UISegmentedControl!
  @IBOutlet weak var markLabel: UILabel!
  @IBOutlet weak var modelLabel: UILabel!
  @IBOutlet weak var carImageView: UIImageView!
  @IBOutlet weak var lastTimeStartedLabel: UILabel!
  @IBOutlet weak var numberOfTripsLabel: UILabel!
  @IBOutlet weak var ratingLabel: UILabel!
  @IBOutlet weak var myChoiceImageView: UIImageView!
  
  //как только экран загрузился
  override func viewDidLoad() {
    super.viewDidLoad()
    
      //получаем информацию с файла (только 1 раз)
    getDataFromFile()
    
    let fetchRequest: NSFetchRequest<Car> = Car.fetchRequest()
    let mark = segmentedControl.titleForSegment(at: 0)
    fetchRequest.predicate = NSPredicate(format: "mark == %@", mark!)
    
    do {
      let results = try context.fetch(fetchRequest)
      selectedCar = results[0]
      insertDataFrom(selectedCar: selectedCar)
    } catch {
      print(error.localizedDescription)
    }
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
    //вставляем данные в наши лейблы
  func insertDataFrom(selectedCar: Car) {
    carImageView.image = UIImage(data: selectedCar.imageData! as Data)
    markLabel.text = selectedCar.mark
    modelLabel.text = selectedCar.model
    myChoiceImageView.isHidden = !(selectedCar.myChoice?.boolValue)!
    ratingLabel.text = "Rating: \(selectedCar.rating!.doubleValue) / 10.0"
    numberOfTripsLabel.text = "Number of trips: \(selectedCar.timesDriven!.intValue)"
    
    let df = DateFormatter()
    df.dateStyle = .short
    df.timeStyle = .none
    lastTimeStartedLabel.text = "Last time started: \(df.string(from: selectedCar.lastStarted! as Date))"
    segmentedControl.tintColor = selectedCar.tintColor as? UIColor
  
  }
  
    //получаем данные с файла
  func getDataFromFile() {
    let fetchRequest: NSFetchRequest<Car> = Car.fetchRequest()
    fetchRequest.predicate = NSPredicate(format: "mark != nil")
    
    var records = 0
    
    do {
      let count = try context.count(for: fetchRequest)  //получаем сколько у нас значений
      records = count
      print("Data is there already?")
    } catch {
      print(error.localizedDescription)
    }
    
    guard records == 0 else { return } //если колличество элементов в памяти 0 то добавляем из файла
    
    let pathToFile = Bundle.main.path(forResource: "data", ofType: "plist") //поиск файла
    let dataArray = NSArray(contentsOfFile: pathToFile!)!
    
      //переводим массив в элементы
    for dictionary in dataArray {
        
        //core data
      let entity = NSEntityDescription.entity(forEntityName: "Car", in: context)
      let car = NSManagedObject(entity: entity!, insertInto: context) as! Car
      
      let carDictionary = dictionary as! NSDictionary
      car.mark = carDictionary["mark"] as? String
      car.model = carDictionary["model"] as? String
      car.rating = carDictionary["rating"] as? NSNumber
      car.lastStarted = carDictionary["lastStarted"] as? Date
      car.timesDriven = carDictionary["timesDriven"] as? NSNumber
      car.myChoice = carDictionary["myChoice"] as? NSNumber
      
      let imageName = carDictionary["imageName"] as? String
      let image = UIImage(named: imageName!)
      let imageData = image!.pngData()
      car.imageData = imageData as Data?
      
      let colorDictionary = carDictionary["tintColor"] as? NSDictionary
      car.tintColor = getColor(colorDictionary: colorDictionary!)
    }
  }
  
  func getColor(colorDictionary: NSDictionary) -> UIColor {
    let red = colorDictionary["red"] as! NSNumber
    let green = colorDictionary["green"] as! NSNumber
    let blue = colorDictionary["blue"] as! NSNumber
    
    return UIColor(red: CGFloat(red.floatValue) / 255, green: CGFloat(green.floatValue) / 255, blue: CGFloat(blue.floatValue) / 255, alpha: 1)
  }
  
    
    //когда мы переходим по сегментам
  @IBAction func segmentedCtrlPressed(_ sender: UISegmentedControl) {
    
    let mark = sender.titleForSegment(at: sender.selectedSegmentIndex)
    let fetchRequest: NSFetchRequest<Car> = Car.fetchRequest()
      
    fetchRequest.predicate = NSPredicate(format: "mark == %@", mark!)
    
    do {
      let results = try context.fetch(fetchRequest)
      selectedCar = results[0]
      insertDataFrom(selectedCar: selectedCar)
    } catch {
      print(error.localizedDescription)
    }
  }
  
    //меняяем рейтинг сохраняем контекст и вставляем в лейблы
  @IBAction func startEnginePressed(_ sender: UIButton) {
    let timesDriven = selectedCar.timesDriven?.intValue
    selectedCar.timesDriven = NSNumber(value: timesDriven! + 1)
    selectedCar.lastStarted = Date()
    
    do {
      try context.save()
      insertDataFrom(selectedCar: selectedCar)
    } catch {
      print(error.localizedDescription)
    }
  }
  
    //нажатие на рейтинг
  @IBAction func rateItPressed(_ sender: UIButton) {
    
    let ac = UIAlertController(title: "Rate it", message: "Rate this car please", preferredStyle: .alert)
    let ok = UIAlertAction(title: "OK", style: .default) {
      action in
      
      let textField = ac.textFields?[0]
      self.update(rating: textField!.text!)
    }
    let cancel = UIAlertAction(title: "Cancel", style: .default)
    
    ac.addTextField {
      textField in
      textField.keyboardType = .numberPad
    }
    
    ac.addAction(ok)
    ac.addAction(cancel)
    present(ac, animated: true)
  }
  
    //обновляем рейтинг
  func update(rating: String) {
    selectedCar.rating = NSNumber(value: Double(rating)!)
    
    do {
      try context.save()
      insertDataFrom(selectedCar: selectedCar)
    } catch {
      
      let ac = UIAlertController(title: "Wrong value", message: "Wrong input", preferredStyle: .alert)
      let ok = UIAlertAction(title: "OK", style: .default)
      ac.addAction(ok)
      present(ac, animated: true, completion: nil)
      print(error.localizedDescription)
    }
  }
}











